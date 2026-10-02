package tech.lolli.toolbox.alert

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class CfAlertParserTest {

    private fun sampleServerJson(
        id: String = "node-1",
        name: String = "Tokyo Node",
        trafficLimit: String = "10TB",
        calcType: String = "down",
        rxMonthly: Long = (9.2 * 1024 * 1024 * 1024 * 1024).toLong(), // 9.2TB
        txMonthly: Long = (1.0 * 1024 * 1024 * 1024 * 1024).toLong(),
        expireDate: String = "2026-10-07",
    ): String = """
    {
      "servers": [{
        "id": "$id",
        "name": "$name",
        "traffic_limit": "$trafficLimit",
        "traffic_calc_type": "$calcType",
        "net_rx_monthly": $rxMonthly,
        "net_tx_monthly": $txMonthly,
        "expire_date": "$expireDate"
      }]
    }
    """.trimIndent()

    @Test
    fun nodeAt92PercentTrafficWithThreshold90TriggersAlert() {
        val json = sampleServerJson(rxMonthly = (9.2 * 1024 * 1024 * 1024 * 1024).toLong()) // 92% of 10TB
        val state = mutableMapOf<String, String>()
        val today = LocalDate.of(2026, 10, 2)

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = today,
        )

        assertEquals(1, alerts.filter { it.kind == CfAlertParser.AlertKind.TRAFFIC }.size)
        val alert = alerts.first { it.kind == CfAlertParser.AlertKind.TRAFFIC }
        assertEquals("node-1", alert.nodeId)
        assertEquals(90, alert.tierOrDays)
        assertEquals(90, state["alert_node-1_traffic"]?.toIntOrNull())
    }

    @Test
    fun nodeAt93PercentWhen90TierAlreadyNotifiedDoesNotReNotify() {
        val json = sampleServerJson(rxMonthly = (9.3 * 1024 * 1024 * 1024 * 1024).toLong()) // 93% of 10TB
        val state = mutableMapOf<String, String>("alert_node-1_traffic" to "90")
        val today = LocalDate.of(2026, 10, 2)

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = today,
        )

        assertEquals(0, alerts.filter { it.kind == CfAlertParser.AlertKind.TRAFFIC }.size)
    }

    @Test
    fun nodeEscalatesFrom90To96With95TierTriggersAlert() {
        val json = sampleServerJson(rxMonthly = (9.6 * 1024 * 1024 * 1024 * 1024).toLong()) // 96% of 10TB
        val state = mutableMapOf<String, String>("alert_node-1_traffic" to "90")
        val today = LocalDate.of(2026, 10, 2)

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90, // threshold can be 80/90/95
            expiryDays = 7,
            state = state,
            today = today,
        )

        val trafficAlerts = alerts.filter { it.kind == CfAlertParser.AlertKind.TRAFFIC }
        assertEquals(1, trafficAlerts.size)
        assertEquals(95, trafficAlerts[0].tierOrDays)
        assertEquals(95, state["alert_node-1_traffic"]?.toIntOrNull())
    }

    @Test
    fun nodeExpiryIn5DaysWithThreshold7TriggersAlert() {
        val json = sampleServerJson(expireDate = "2026-10-07") // 5 days from 2026-10-02
        val state = mutableMapOf<String, String>()
        val today = LocalDate.of(2026, 10, 2)

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = today,
        )

        val expireAlerts = alerts.filter { it.kind == CfAlertParser.AlertKind.EXPIRE }
        assertEquals(1, expireAlerts.size)
        assertEquals(5, expireAlerts[0].tierOrDays)
        assertEquals("2026-10-02", state["alert_node-1_expire"])
    }

    @Test
    fun nodeExpiryAlreadyNotifiedTodayDoesNotReNotifyTodayReNotifiesTomorrow() {
        val json = sampleServerJson(expireDate = "2026-10-07")
        val state = mutableMapOf<String, String>("alert_node-1_expire" to "2026-10-02")
        val today = LocalDate.of(2026, 10, 2)

        // Same day -> no alert
        var alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = today,
        )
        assertEquals(0, alerts.filter { it.kind == CfAlertParser.AlertKind.EXPIRE }.size)

        // Next day -> alert triggers
        val tomorrow = LocalDate.of(2026, 10, 3)
        alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = tomorrow,
        )
        val expireAlerts = alerts.filter { it.kind == CfAlertParser.AlertKind.EXPIRE }
        assertEquals(1, expireAlerts.size)
        assertEquals(4, expireAlerts[0].tierOrDays) // 4 days left
        assertEquals("2026-10-03", state["alert_node-1_expire"])
    }

    @Test
    fun nodeAlreadyExpiredTriggersExpiredAlert() {
        val json = sampleServerJson(expireDate = "2026-10-01") // Expired yesterday
        val state = mutableMapOf<String, String>()
        val today = LocalDate.of(2026, 10, 2)

        val alerts = CfAlertParser.check(
            json = json,
            trafficThresholdPct = 90,
            expiryDays = 7,
            state = state,
            today = today,
        )

        val expiredAlerts = alerts.filter { it.kind == CfAlertParser.AlertKind.EXPIRED }
        assertEquals(1, expiredAlerts.size)
        assertEquals(-1, expiredAlerts[0].tierOrDays)
        assertEquals("2026-10-02", state["alert_node-1_expire"])
    }
}

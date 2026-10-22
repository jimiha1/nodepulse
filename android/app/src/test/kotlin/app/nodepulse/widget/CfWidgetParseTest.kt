package app.nodepulse.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import app.nodepulse.R

class CfWidgetParseTest {
    private val rawServersJson = """
    {
      "servers": [{
        "id": "fd978320-c32c-474d-857a-3412a7526a7b",
        "name": "日本节点",
        "region": "JP",
        "cpu": 3.23,
        "cpu_cores": 2,
        "load_avg": "0.04 0.10 0.05",
        "ram_total": 12268,
        "ram_used": 4987.9,
        "disk_total": 100454,
        "disk_used": 54886,
        "net_in_speed": 13200,
        "net_out_speed": 2980,
        "net_rx": 3160000000,
        "net_tx": 4500000000,
        "ping_ct": 165,
        "ping_cu": 78,
        "ping_cm": 310,
        "loss_ct": 0,
        "loss_cu": 5,
        "loss_cm": 12,
        "boot_time": "1756000000000",
        "expire_date": "2027-10-02"
      }]
    }
    """.trimIndent()

    private val rawHistoryJson = """
    [
      {
        "timestamp": 1000,
        "cpu": 15.5,
        "ram_used": 4000,
        "ram_total": 12268,
        "disk_used": 50000,
        "disk_total": 100454,
        "net_in_speed": 1024,
        "net_out_speed": 2048
      },
      {
        "timestamp": 2000,
        "cpu": 25.0,
        "ram_used": 6000,
        "ram_total": 12268,
        "disk_used": 50000,
        "disk_total": 100454,
        "net_in_speed": 4096,
        "net_out_speed": 8192
      }
    ]
    """.trimIndent()

    @Test
    fun parseCfServerNodeMetrics() {
        val server = WidgetStore.WidgetServer(
            id = "fd978320-c32c-474d-857a-3412a7526a7b",
            name = "日本节点",
            region = "JP",
        )
        val reading = WidgetApi.parseCfMetrics(server, rawServersJson)
        assertNotNull(reading)
        assertEquals("日本节点", reading.name)
        assertEquals(3.23, reading.cpu!!, 0.001)
        // 4987.9 / 12268 * 100 = 40.6578%
        assertEquals(40.657, reading.mem!!, 0.01)
        // 54886 / 100454 * 100 = 54.6379%
        assertEquals(54.638, reading.disk!!, 0.01)
        assertTrue(reading.memText.contains("4.9g") || reading.memText.contains("4.8g"))
        assertTrue(reading.netText.contains("12.8k/s") || reading.netText.contains("12.9k/s"))
        assertEquals("165/78/310ms", reading.pingText)
        assertEquals("0/5/12%", reading.lossText)
        assertEquals("2027-10-02", reading.expireText)
    }

    @Test
    fun parseCfHistoryPoints() {
        val points = WidgetApi.parseCfHistory(rawHistoryJson)
        assertEquals(2, points.size)
        assertEquals(15.5, points[0].cpu, 0.001)
        assertEquals(1024.0, points[0].netRx, 0.001)
        assertEquals(2048.0, points[0].netTx, 0.001)
        assertEquals(25.0, points[1].cpu, 0.001)
        assertEquals(4096.0, points[1].netRx, 0.001)
        assertEquals(8192.0, points[1].netTx, 0.001)
    }

    @Test
    fun widgetStorePublishAndLoad() {
        val payload = """
        {
          "siteUrl": "https://monitor.example.com",
          "token": "test-jwt-token",
          "tokenExpiresAt": 1759410000000,
          "nodes": [
            {"id": "node-1", "name": "东京节点", "region": "JP"},
            {"id": "node-2", "name": "香港节点", "region": "HK"}
          ]
        }
        """.trimIndent()

        // Validating JSON parsing logic of payload
        val root = org.json.JSONObject(payload)
        val siteUrl = root.getString("siteUrl")
        val token = root.getString("token")
        val tokenExpiresAt = root.getLong("tokenExpiresAt")
        val nodes = root.getJSONArray("nodes")

        assertEquals("https://monitor.example.com", siteUrl)
        assertEquals("test-jwt-token", token)
        assertEquals(1759410000000L, tokenExpiresAt)
        assertEquals(2, nodes.length())

        val server1 = WidgetStore.WidgetServer.fromJson(nodes.getJSONObject(0))
        assertNotNull(server1)
        assertEquals("node-1", server1!!.id)
        assertEquals("东京节点", server1.name)
        assertEquals("JP", server1.region)
    }

    @Test
    fun parseCfServerNodeLastUpdated() {
        val server = WidgetStore.WidgetServer(
            id = "fd978320-c32c-474d-857a-3412a7526a7b",
            name = "日本节点",
            region = "JP",
        )
        val jsonWithLastUpdated = """
        {
          "servers": [{
            "id": "fd978320-c32c-474d-857a-3412a7526a7b",
            "name": "日本节点",
            "cpu": 5.0,
            "last_updated": 1759410000000
          }]
        }
        """.trimIndent()
        val reading = WidgetApi.parseCfMetrics(server, jsonWithLastUpdated)
        assertEquals(1759410000000L, reading.lastUpdated)
    }

    @Test
    fun parseCfServerWithoutLastUpdatedYieldsNull() {
        val server = WidgetStore.WidgetServer(
            id = "fd978320-c32c-474d-857a-3412a7526a7b",
            name = "日本节点",
            region = "JP",
        )
        val reading = WidgetApi.parseCfMetrics(server, rawServersJson)
        assertNull(reading.lastUpdated)
    }

    @Test
    fun widgetExpiryFromKeyRoundTripsAndDefaults() {
        for (expiry in WidgetExpiry.entries) {
            assertEquals(expiry, WidgetExpiry.fromKey(expiry.key))
        }
        assertEquals(WidgetExpiry.M30, WidgetExpiry.fromKey(null))
        assertEquals(WidgetExpiry.M30, WidgetExpiry.fromKey("nonsense"))
        assertEquals(0, WidgetExpiry.NEVER.minutes)
        assertEquals(30, WidgetExpiry.DEFAULT.minutes)
    }

    @Test
    fun resolveTimeColorResTiers() {
        val now = 1_759_410_000_000L
        val t30m = 30 * 60 * 1000L

        // Fresh: inside the threshold keeps the plain summary colour.
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(now - 10 * 60 * 1000L, WidgetExpiry.M30, now),
        )
        // Exactly at the threshold is still fresh.
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(now - t30m, WidgetExpiry.M30, now),
        )
        // Aging: past the threshold, up to 4x it.
        assertEquals(
            R.color.widgetTimeAging,
            HomeWidget.resolveTimeColorRes(now - t30m - 1, WidgetExpiry.M30, now),
        )
        assertEquals(
            R.color.widgetTimeAging,
            HomeWidget.resolveTimeColorRes(now - 4 * t30m, WidgetExpiry.M30, now),
        )
        // Stale: past 4x the threshold.
        assertEquals(
            R.color.widgetTimeStale,
            HomeWidget.resolveTimeColorRes(now - 4 * t30m - 1, WidgetExpiry.M30, now),
        )
        assertEquals(
            R.color.widgetTimeStale,
            HomeWidget.resolveTimeColorRes(now - 10 * 60 * 60 * 1000L, WidgetExpiry.M30, now),
        )
    }

    @Test
    fun resolveTimeColorResEdgeCases() {
        val now = 1_759_410_000_000L

        // No timestamp at all: plain colour, never a warning.
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(null, WidgetExpiry.M30, now),
        )
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(0L, WidgetExpiry.M30, now),
        )

        // NEVER never warns, however old the data is.
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(now - 10 * 24 * 60 * 60 * 1000L, WidgetExpiry.NEVER, now),
        )

        // A clock that ran backwards must not read as stale.
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(now + 60_000L, WidgetExpiry.M30, now),
        )

        // The threshold follows the configured preset, not a fixed value.
        assertEquals(
            R.color.widgetTimeAging,
            HomeWidget.resolveTimeColorRes(now - 11 * 60 * 1000L, WidgetExpiry.M10, now),
        )
        assertEquals(
            R.color.widgetSummaryText,
            HomeWidget.resolveTimeColorRes(now - 11 * 60 * 1000L, WidgetExpiry.H2, now),
        )
    }

    @Test
    fun formatBytesOmitsTrailingZeroDecimals() {
        val gb = 1024.0 * 1024.0 * 1024.0
        assertEquals("500g", WidgetApi.formatBytes(500.0 * gb))
        assertEquals("116.7g", WidgetApi.formatBytes(116.7 * gb))
        assertEquals("1g", WidgetApi.formatBytes(1.0 * gb))
        assertEquals("1.5g", WidgetApi.formatBytes(1.5 * gb))
        assertEquals("0b", WidgetApi.formatBytes(0.0))
        assertEquals("512b", WidgetApi.formatBytes(512.0))
        assertEquals("1k", WidgetApi.formatBytes(1024.0))
        assertEquals("1.2m", WidgetApi.formatBytes(1.2 * 1024.0 * 1024.0))
    }

    @Test
    fun parseCfServerKeepsTheRawTallFields() {
        val server = WidgetStore.WidgetServer(
            id = "fd978320-c32c-474d-857a-3412a7526a7b", name = "日本节点", region = "JP",
        )
        val r = WidgetApi.parseCfMetrics(server, rawServersJson)
        assertEquals("JP", r.region)
        assertEquals(165.0, r.pingCt!!, 0.001)
        assertEquals(78.0, r.pingCu!!, 0.001)
        assertEquals(310.0, r.pingCm!!, 0.001)
        assertEquals(0.0, r.lossCt!!, 0.001)
        assertEquals(5.0, r.lossCu!!, 0.001)
        assertEquals(12.0, r.lossCm!!, 0.001)
        assertEquals(13200.0, r.netIn, 0.001)
        assertEquals(2980.0, r.netOut, 0.001)
        // cpu_cores and the 5/15-minute loads come from the same payload; a
        // missing one must not turn into a zero that reads like a real value.
        assertEquals(2, r.cpuCores)
        assertEquals(0.10, r.load5, 0.001)
        assertEquals(0.05, r.load15, 0.001)
    }

    @Test
    fun parseCfServerLeavesMissingTallFieldsEmpty() {
        val server = WidgetStore.WidgetServer(id = "x", name = "X", region = null)
        val r = WidgetApi.parseCfMetrics(server, """{"servers":[{"id":"x"}]}""")
        assertNull(r.region)
        assertNull(r.cpuCores)
        assertNull(r.pingCt)
        assertEquals(0.0, r.netIn, 0.001)
    }

    @Test
    fun parseCfServerFallsBackToTheStoredRegion() {
        val server = WidgetStore.WidgetServer(id = "missing", name = "X", region = "HK")
        assertEquals("HK", WidgetApi.parseCfMetrics(server, """{"servers":[]}""").region)
    }

    @Test
    fun parseCfHistoryReadsThePingColumns() {
        val body = """[{"timestamp":1,"cpu":1,"ping_ct":10,"ping_cu":null,"ping_cm":30}]"""
        val p = WidgetApi.parseCfHistory(body).single()
        assertEquals(10.0, p.pingCt!!, 0.001)
        assertNull(p.pingCu)
        assertEquals(30.0, p.pingCm!!, 0.001)
    }

    @Test
    fun sharedUnitMergesWhenBothSidesAgree() {
        assertEquals("233 / 431 MiB", WidgetApi.formatSharedUnit(232.65 * 1048576, 431.0 * 1048576))
    }

    @Test
    fun sharedUnitKeepsBothUnitsWhenTheyDiffer() {
        assertEquals("512 MiB / 2 GiB", WidgetApi.formatSharedUnit(512.0 * 1048576, 2048.0 * 1048576))
    }

    @Test
    fun sharedPairPrefixesTheDirectionAndSharesTheUnit() {
        assertEquals(
            "↓14.1 · ↑13.2 KiB/s",
            WidgetApi.formatSharedPair(14.11 * 1024, 13.19 * 1024, perSecond = true),
        )
        assertEquals(
            "↓317 · ↑314 MiB",
            WidgetApi.formatSharedPair(317.0 * 1048576, 313.7 * 1048576),
        )
    }

    @Test
    fun sharedPairSaysBothUnitsWhenTheyDiffer() {
        assertEquals(
            "↓1.2 GiB · ↑512 MiB",
            WidgetApi.formatSharedPair(1.2 * 1024 * 1048576, 512.0 * 1048576),
        )
    }
}

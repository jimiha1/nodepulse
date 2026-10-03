package tech.lolli.toolbox.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CfWidgetParseTest {
    private val rawServersJson = """
    {
      "servers": [{
        "id": "fd978320-c32c-474d-857a-3412a7526a7b",
        "name": "日本节点",
        "region": "JP",
        "cpu": 3.23,
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
}

package tech.lolli.toolbox.alert

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ResourceAlertEvaluatorTest {

    private val server = ResourceAlertEvaluator.Server("srv-1", "Osaka")

    /** A history row with only the column a test cares about set. */
    private fun row(
        timestamp: Long,
        cpu: Double? = null,
        ramPct: Double? = null,
        netInMbps: Double? = null,
    ) = ResourceAlertEvaluator.Row(
        timestamp = timestamp,
        cpu = cpu,
        ramPct = ramPct,
        diskPct = null,
        netInMbps = netInMbps,
        netOutMbps = null,
    )

    private fun rule(
        id: String = "r1",
        metric: ResourceAlertEvaluator.Metric = ResourceAlertEvaluator.Metric.CPU,
        threshold: Double = 80.0,
        serverId: String? = null,
        windowMinutes: Int = 5,
        trigger: ResourceAlertEvaluator.Trigger = ResourceAlertEvaluator.Trigger.AVG,
        enabled: Boolean = true,
    ) = ResourceAlertEvaluator.Rule(
        id = id,
        name = "CPU high",
        metric = metric,
        threshold = threshold,
        serverId = serverId,
        windowMinutes = windowMinutes,
        trigger = trigger,
        enabled = enabled,
    )

    private fun evaluate(
        rules: List<ResourceAlertEvaluator.Rule>,
        rows: List<ResourceAlertEvaluator.Row>,
        state: MutableMap<String, String> = mutableMapOf(),
        servers: List<ResourceAlertEvaluator.Server> = listOf(server),
        now: Long = 1_000_000L,
    ) = ResourceAlertEvaluator.evaluate(
        rules = rules,
        servers = servers,
        histories = mapOf(server.id to rows),
        state = state,
        now = now,
    )

    // --- window arithmetic -------------------------------------------------

    @Test
    fun onlyRowsInsideTheWindowCount() {
        val now = 1_000_000L
        val rows = listOf(
            row(now - 6 * 60_000L, cpu = 99.0), // outside a 5-minute window
            row(now - 4 * 60_000L, cpu = 10.0),
            row(now - 1 * 60_000L, cpu = 10.0),
        )
        // Mean of the two inside is 10, so a threshold of 80 stays quiet even
        // though the row outside would have pushed nothing either way — the
        // point is that it is not counted at all.
        assertEquals(0, evaluate(listOf(rule(threshold = 80.0)), rows, now = now).size)

        // And the row inside the window is what fires: threshold 5 is under 10.
        assertEquals(1, evaluate(listOf(rule(threshold = 5.0)), rows, now = now).size)
    }

    @Test
    fun aRowExactlyAtTheWindowEdgeCounts() {
        val now = 1_000_000L
        val rows = listOf(
            row(now - 5 * 60_000L, cpu = 90.0),
            row(now - 1 * 60_000L, cpu = 90.0),
        )
        assertEquals(1, evaluate(listOf(rule(threshold = 80.0)), rows, now = now).size)
    }

    @Test
    fun tooFewSamplesIsNotJudged() {
        val now = 1_000_000L
        val state = mutableMapOf<String, String>()

        // One sample over the threshold: a point reading, not a window.
        val one = listOf(row(now - 1_000L, cpu = 99.0))
        assertEquals(0, evaluate(listOf(rule()), one, state, now = now).size)

        // No samples at all.
        assertEquals(0, evaluate(listOf(rule()), emptyList(), state, now = now).size)
    }

    @Test
    fun rowsWithoutTheMetricAreNotSamples() {
        val now = 1_000_000L
        // Both rows are in the window, but neither carries CPU: a history with
        // the column missing is not a window of zeroes.
        val rows = listOf(row(now - 60_000L), row(now - 30_000L))
        assertEquals(0, evaluate(listOf(rule()), rows, now = now).size)
    }

    // --- triggers ----------------------------------------------------------

    @Test
    fun avgFiresOnTheMeanNotOnEverySample() {
        val now = 1_000_000L
        val rows = listOf(
            row(now - 3 * 60_000L, cpu = 100.0),
            row(now - 2 * 60_000L, cpu = 100.0),
            row(now - 1 * 60_000L, cpu = 10.0),
        )
        // Mean 70: over 60, under 80.
        assertEquals(1, evaluate(listOf(rule(threshold = 60.0)), rows, now = now).size)
        assertEquals(0, evaluate(listOf(rule(threshold = 80.0)), rows, now = now).size)
    }

    @Test
    fun allRequiresEverySampleOverTheThreshold() {
        val now = 1_000_000L
        val rows = listOf(
            row(now - 3 * 60_000L, cpu = 90.0),
            row(now - 2 * 60_000L, cpu = 90.0),
            row(now - 1 * 60_000L, cpu = 10.0),
        )
        val trigger = ResourceAlertEvaluator.Trigger.ALL
        assertEquals(0, evaluate(listOf(rule(threshold = 80.0, trigger = trigger)), rows, now = now).size)

        val allOver = listOf(
            row(now - 3 * 60_000L, cpu = 90.0),
            row(now - 1 * 60_000L, cpu = 90.0),
        )
        assertEquals(1, evaluate(listOf(rule(threshold = 80.0, trigger = trigger)), allOver, now = now).size)
    }

    @Test
    fun aSampleEqualToTheThresholdDoesNotFire() {
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 80.0), row(now - 60_000L, cpu = 80.0))
        // "超过阈值" is strictly over: exactly at it is not over it.
        assertEquals(0, evaluate(listOf(rule(threshold = 80.0)), rows, now = now).size)
        assertEquals(
            0,
            evaluate(
                listOf(rule(threshold = 80.0, trigger = ResourceAlertEvaluator.Trigger.ALL)),
                rows,
                now = now,
            ).size,
        )
    }

    // --- dedup -------------------------------------------------------------

    @Test
    fun aFiringRuleAlertsOnceAndAgainOnlyAfterItRecovers() {
        val now = 1_000_000L
        val state = mutableMapOf<String, String>()
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))
        val rules = listOf(rule(threshold = 80.0))

        assertEquals(1, evaluate(rules, rows, state, now = now).size)
        assertEquals("1", state[ResourceAlertEvaluator.stateKey("r1", "srv-1")])

        // Still firing on the next run: no second notification.
        assertEquals(0, evaluate(rules, rows, state, now = now + 15 * 60_000L).size)

        // Recovered, then firing again: a new episode, so it alerts again.
        val recovered = listOf(
            row(now + 15 * 60_000L - 2 * 60_000L, cpu = 10.0),
            row(now + 15 * 60_000L - 60_000L, cpu = 10.0),
        )
        assertEquals(0, evaluate(rules, recovered, state, now = now + 15 * 60_000L).size)
        assertNull(state[ResourceAlertEvaluator.stateKey("r1", "srv-1")])

        val firingAgain = listOf(
            row(now + 30 * 60_000L - 2 * 60_000L, cpu = 95.0),
            row(now + 30 * 60_000L - 60_000L, cpu = 95.0),
        )
        assertEquals(1, evaluate(rules, firingAgain, state, now = now + 30 * 60_000L).size)
    }

    @Test
    fun anUnjudgeableWindowKeepsTheStateSoARecoveredNodeDoesNotReAlert() {
        val now = 1_000_000L
        val state = mutableMapOf(ResourceAlertEvaluator.stateKey("r1", "srv-1") to "1")
        val rules = listOf(rule(threshold = 80.0))

        // The node stopped reporting: no rows at all. That is not "recovered".
        assertEquals(0, evaluate(rules, emptyList(), state, now = now).size)
        assertEquals("1", state[ResourceAlertEvaluator.stateKey("r1", "srv-1")])

        // It comes back over the threshold: still the same episode.
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))
        assertEquals(0, evaluate(rules, rows, state, now = now).size)
    }

    @Test
    fun rulesAreDedupedPerServerNotPerRule() {
        val other = ResourceAlertEvaluator.Server("srv-2", "Tokyo")
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))
        val state = mutableMapOf<String, String>()
        val alerts = ResourceAlertEvaluator.evaluate(
            rules = listOf(rule(threshold = 80.0)),
            servers = listOf(server, other),
            histories = mapOf(server.id to rows, other.id to rows),
            state = state,
            now = now,
        )
        assertEquals(2, alerts.size)
        assertEquals(setOf("srv-1", "srv-2"), alerts.map { it.serverId }.toSet())
    }

    @Test
    fun aRuleNamingOneServerOnlyWatchesThatServer() {
        val other = ResourceAlertEvaluator.Server("srv-2", "Tokyo")
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))
        val alerts = ResourceAlertEvaluator.evaluate(
            rules = listOf(rule(threshold = 80.0, serverId = "srv-2")),
            servers = listOf(server, other),
            histories = mapOf(server.id to rows, other.id to rows),
            state = mutableMapOf(),
            now = now,
        )
        assertEquals(1, alerts.size)
        assertEquals("srv-2", alerts.single().serverId)
    }

    @Test
    fun aRuleForANodeTheSiteNoLongerReportsIsSkipped() {
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))
        val alerts = evaluate(listOf(rule(threshold = 80.0, serverId = "gone")), rows, now = now)
        assertEquals(0, alerts.size)
    }

    @Test
    fun aDisabledRuleIsNotEvaluatedAndKeepsItsState() {
        val now = 1_000_000L
        val key = ResourceAlertEvaluator.stateKey("r1", "srv-1")
        val state = mutableMapOf(key to "1")
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 95.0))

        assertEquals(0, evaluate(listOf(rule(enabled = false)), rows, state, now = now).size)
        assertEquals("1", state[key])
    }

    @Test
    fun pruneStateDropsDeletedRulesAndKeepsTheRest() {
        val state = mutableMapOf(
            ResourceAlertEvaluator.stateKey("r1", "srv-1") to "1",
            ResourceAlertEvaluator.stateKey("r2", "srv-1") to "1",
            "alert_srv-1_traffic" to "90",
        )
        ResourceAlertEvaluator.pruneState(listOf(rule(id = "r2")), state)
        assertNull(state[ResourceAlertEvaluator.stateKey("r1", "srv-1")])
        assertEquals("1", state[ResourceAlertEvaluator.stateKey("r2", "srv-1")])
        assertEquals("90", state["alert_srv-1_traffic"])
    }

    // --- payload parsing ---------------------------------------------------

    @Test
    fun parseRulesReadsWhatTheAppWrites() {
        val json = JSONArray(
            """
            [
              {"id":"rabc","name":"CPU 高","metric":"cpu","threshold":80.5,
               "windowMinutes":5,"trigger":"avg","enabled":true},
              {"id":"rdef","name":"出口带宽","metric":"netOut","threshold":50,
               "serverId":"srv-1","serverName":"Osaka","windowMinutes":15,
               "trigger":"all","enabled":false}
            ]
            """.trimIndent()
        )
        val rules = ResourceAlertEvaluator.parseRules(json)
        assertEquals(2, rules.size)

        val first = rules[0]
        assertEquals("rabc", first.id)
        assertEquals("CPU 高", first.name)
        assertEquals(ResourceAlertEvaluator.Metric.CPU, first.metric)
        assertEquals(80.5, first.threshold, 0.0)
        assertNull(first.serverId)
        assertEquals(5, first.windowMinutes)
        assertEquals(ResourceAlertEvaluator.Trigger.AVG, first.trigger)
        assertTrue(first.enabled)

        val second = rules[1]
        assertEquals(ResourceAlertEvaluator.Metric.NET_OUT, second.metric)
        assertEquals("srv-1", second.serverId)
        assertEquals(ResourceAlertEvaluator.Trigger.ALL, second.trigger)
        assertEquals(false, second.enabled)
    }

    @Test
    fun parseRulesSkipsWhatItCannotUse() {
        val json = JSONArray(
            """
            [
              {"name":"no id","metric":"cpu","threshold":80,"windowMinutes":5,"trigger":"avg"},
              {"id":"r1","metric":"wat","threshold":80,"windowMinutes":5,"trigger":"avg"},
              {"id":"r2","metric":"cpu","threshold":80,"windowMinutes":5,"trigger":"wat"},
              {"id":"r3","metric":"cpu","windowMinutes":5,"trigger":"avg"},
              {"id":"r4","metric":"cpu","threshold":80,"windowMinutes":0,"trigger":"avg"},
              {"id":"r5","metric":"cpu","threshold":80,"windowMinutes":5,"trigger":"avg"}
            ]
            """.trimIndent()
        )
        val rules = ResourceAlertEvaluator.parseRules(json)
        assertEquals(1, rules.size)
        assertEquals("r5", rules.single().id)
        // A name the payload omitted falls back to the metric's own name.
        assertEquals("cpu", rules.single().name)
    }

    @Test
    fun parseRulesSurvivesGarbage() {
        assertEquals(0, ResourceAlertEvaluator.parseRules(null as JSONArray?).size)
        assertEquals(0, ResourceAlertEvaluator.parseStoredRules(null).size)
        assertEquals(0, ResourceAlertEvaluator.parseStoredRules("").size)
        assertEquals(0, ResourceAlertEvaluator.parseStoredRules("not json").size)
    }

    // --- history parsing ---------------------------------------------------

    @Test
    fun parseRowsReadsTheFixedColumnList() {
        // Shape of a real row of `GET /api/history/all` on the live site.
        val body = """
        [{"timestamp":1790927096022,"cpu":6.51,"ram_total":11943,"ram_used":4912.875,
          "disk_total":100475,"disk_used":54846,"net_in_speed":16115,"net_out_speed":9632}]
        """.trimIndent()
        val rows = ResourceAlertEvaluator.parseRows(body)
        val row = rows.single()
        assertEquals(1790927096022L, row.timestamp)
        assertEquals(6.51, row.cpu!!, 0.0)
        assertEquals(41.13, row.ramPct!!, 0.01)
        assertEquals(54.58, row.diskPct!!, 0.01)
        // 16115 B/s * 8 / 1e6 = 0.12892 Mbps
        assertEquals(0.12892, row.netInMbps!!, 0.0001)
        assertEquals(0.077056, row.netOutMbps!!, 0.0001)
    }

    @Test
    fun parseRowsLeavesMissingColumnsNull() {
        val rows = ResourceAlertEvaluator.parseRows(
            """[{"timestamp":42,"cpu":false,"ram_used":100,"net_in_speed":null}]"""
        )
        val row = rows.single()
        assertNull(row.cpu)
        // A total of zero is not a percentage of anything.
        assertNull(row.ramPct)
        assertNull(row.netInMbps)
        assertNull(row.diskPct)
    }

    @Test
    fun parseRowsDropsRowsWithNoTimestamp() {
        val rows = ResourceAlertEvaluator.parseRows(
            """[{"cpu":10},{"timestamp":0,"cpu":10},{"timestamp":42,"cpu":10}]"""
        )
        assertEquals(1, rows.size)
        assertEquals(42L, rows.single().timestamp)
    }

    @Test
    fun parseRowsSurvivesGarbage() {
        assertEquals(0, ResourceAlertEvaluator.parseRows("not json").size)
        assertEquals(0, ResourceAlertEvaluator.parseRows("{}").size)
        assertEquals(0, ResourceAlertEvaluator.parseRows("[]").size)
    }

    // --- window hours ------------------------------------------------------

    @Test
    fun windowHoursLandsOnARangeTheSiteAccepts() {
        val accepted = setOf(0.167, 0.5, 1.0, 6.0, 12.0, 24.0, 48.0, 96.0, 168.0)
        for (minutes in listOf(5, 10, 15, 30, 60)) {
            assertTrue(
                "windowMinutes=$minutes mapped outside the accepted ranges",
                ResourceAlertEvaluator.windowHours(minutes) in accepted,
            )
        }
    }

    @Test
    fun windowHoursCoversTheWindow() {
        // The endpoint downsamples and caps its row count, so a range's rows do
        // not span the range it names — measured at 58 minutes for `hours=1`.
        // Every window the UI offers therefore has to map to a range strictly
        // wider than itself.
        for (minutes in listOf(5, 10, 15, 30, 60)) {
            val hours = ResourceAlertEvaluator.windowHours(minutes)
            assertTrue(
                "windowMinutes=$minutes is not covered by ${hours}h",
                hours * 60 > minutes,
            )
        }
    }

    @Test
    fun windowHoursParamSpellsWholeNumbersWithoutADecimal() {
        assertEquals("6", ResourceAlertEvaluator.windowHoursParam(60))
        assertEquals("0.167", ResourceAlertEvaluator.windowHoursParam(5))
        assertEquals("1", ResourceAlertEvaluator.windowHoursParam(30))
    }

    // --- notification text -------------------------------------------------

    @Test
    fun theAlertNamesTheRuleAndItsNode() {
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 95.0), row(now - 60_000L, cpu = 90.0))
        val alert = evaluate(listOf(rule(threshold = 80.0)), rows, now = now).single()
        assertEquals("Osaka CPU high", alert.title)
        assertTrue(alert.text, alert.text.contains("92.5"))
        assertTrue(alert.text, alert.text.contains("80"))
        assertTrue(alert.text, alert.text.contains("2"))
    }

    @Test
    fun theAlertTextDropsTrailingZeroes() {
        val now = 1_000_000L
        val rows = listOf(row(now - 2 * 60_000L, cpu = 90.0), row(now - 60_000L, cpu = 90.0))
        val alert = evaluate(listOf(rule(threshold = 80.0)), rows, now = now).single()
        assertTrue(alert.text, !alert.text.contains("90.0"))
        assertTrue(alert.text, alert.text.contains("90%"))
    }
}

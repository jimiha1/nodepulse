package tech.lolli.toolbox.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.Spinner
import android.widget.TextView
import tech.lolli.toolbox.R

/**
 * What a widget shows: which server, mode (for MEDIUM), and metrics/fields.
 */
class WidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var servers: List<WidgetStore.WidgetServer> = emptyList()
    private var kind: WidgetKind = WidgetKind.SMALL

    companion object {
        val CHART_METRICS = listOf(
            "cpu",
            "mem",
            "disk",
            "net",
            "load",
            "io",
            "conn",
            "proc",
            "loss",
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.widget_configure)

        setResult(RESULT_CANCELED)

        appWidgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        kind = HomeWidget.kindOf(applicationContext, appWidgetId) ?: WidgetKind.SMALL
        servers = WidgetStore.servers(applicationContext)

        val form = findViewById<LinearLayout>(R.id.config_form)
        val emptyHint = findViewById<TextView>(R.id.empty_hint)
        if (servers.isEmpty()) {
            form.visibility = View.GONE
            emptyHint.visibility = View.VISIBLE
            return
        }

        val existing = WidgetConfig.load(applicationContext, appWidgetId, kind)
        val serverGroup = buildServerList(existing)

        val mediumModeContainer = findViewById<LinearLayout>(R.id.medium_mode_container)
        val modeGroup = findViewById<RadioGroup>(R.id.mode_group)
        val chartCountContainer = findViewById<LinearLayout>(R.id.chart_count_container)
        val chartCountSpinner = findViewById<Spinner>(R.id.chart_count_spinner)
        val chartContainer = findViewById<LinearLayout>(R.id.chart_container)
        val chartLabel = findViewById<TextView>(R.id.chart_label)
        val metricSpinner = findViewById<Spinner>(R.id.metric_spinner)
        val chart2Container = findViewById<LinearLayout>(R.id.chart2_container)
        val chart2Spinner = findViewById<Spinner>(R.id.chart2_spinner)
        val chart3Container = findViewById<LinearLayout>(R.id.chart3_container)
        val chart3Spinner = findViewById<Spinner>(R.id.chart3_spinner)
        val chart4Container = findViewById<LinearLayout>(R.id.chart4_container)
        val chart4Spinner = findViewById<Spinner>(R.id.chart4_spinner)
        val fieldsContainer = findViewById<LinearLayout>(R.id.fields_container)
        val fieldsCapHint = findViewById<TextView>(R.id.fields_cap_hint)
        val fieldChecks = findViewById<LinearLayout>(R.id.field_checks)

        // Setup Spinners for Charts
        val metricLabels = CHART_METRICS.map { metricLabel(it) }
        val spinnerAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_dropdown_item,
            metricLabels,
        )
        metricSpinner.adapter = spinnerAdapter
        chart2Spinner.adapter = spinnerAdapter
        chart3Spinner.adapter = spinnerAdapter
        chart4Spinner.adapter = spinnerAdapter

        val chartCountOptions = listOf(1, 2, 4)
        val chartCountAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_spinner_dropdown_item,
            chartCountOptions.map { "$it" },
        )
        chartCountSpinner.adapter = chartCountAdapter
        val initialCountIndex = chartCountOptions.indexOf(existing.chartCount).coerceAtLeast(0)
        chartCountSpinner.setSelection(initialCountIndex)

        metricSpinner.setSelection(CHART_METRICS.indexOf(existing.chart).coerceAtLeast(0))
        chart2Spinner.setSelection(CHART_METRICS.indexOf(existing.chart2).coerceAtLeast(0))
        chart3Spinner.setSelection(CHART_METRICS.indexOf(existing.chart3).coerceAtLeast(0))
        chart4Spinner.setSelection(CHART_METRICS.indexOf(existing.chart4).coerceAtLeast(0))

        // Setup Field Checkboxes
        val checkBoxes = mutableMapOf<WidgetField, CheckBox>()
        fieldChecks.removeAllViews()
        for (field in WidgetField.entries) {
            val cb = CheckBox(this).apply {
                text = fieldLabel(field)
                isChecked = existing.fields.contains(field)
            }
            checkBoxes[field] = cb
            fieldChecks.addView(cb)
        }

        fun updateUI() {
            if (kind == WidgetKind.SMALL) {
                mediumModeContainer.visibility = View.GONE
                chartCountContainer.visibility = View.GONE
                chartContainer.visibility = View.GONE
                chart2Container.visibility = View.GONE
                chart3Container.visibility = View.GONE
                chart4Container.visibility = View.GONE
                fieldsContainer.visibility = View.VISIBLE
                fieldsCapHint.text = "(Max ${WidgetConfig.CAP_SMALL_FIELDS})"
            } else {
                mediumModeContainer.visibility = View.VISIBLE
                val selectedMode = when (modeGroup.checkedRadioButtonId) {
                    R.id.mode_reading -> MediumMode.READING
                    R.id.mode_combined -> MediumMode.COMBINED
                    else -> MediumMode.CHART
                }
                when (selectedMode) {
                    MediumMode.CHART -> {
                        chartCountContainer.visibility = View.VISIBLE
                        val count = chartCountOptions.getOrElse(chartCountSpinner.selectedItemPosition) { 1 }
                        chartContainer.visibility = View.VISIBLE
                        chartLabel.text = if (count == 1) getString(R.string.widget_configure_metric) else getString(R.string.widget_chart_1)
                        chart2Container.visibility = if (count >= 2) View.VISIBLE else View.GONE
                        chart3Container.visibility = if (count >= 4) View.VISIBLE else View.GONE
                        chart4Container.visibility = if (count >= 4) View.VISIBLE else View.GONE
                        fieldsContainer.visibility = View.GONE
                    }
                    MediumMode.READING -> {
                        chartCountContainer.visibility = View.GONE
                        chartContainer.visibility = View.GONE
                        chart2Container.visibility = View.GONE
                        chart3Container.visibility = View.GONE
                        chart4Container.visibility = View.GONE
                        fieldsContainer.visibility = View.VISIBLE
                        fieldsCapHint.text = "(Max ${WidgetConfig.CAP_MEDIUM_READING_FIELDS})"
                    }
                    MediumMode.COMBINED -> {
                        chartCountContainer.visibility = View.GONE
                        chartContainer.visibility = View.VISIBLE
                        chartLabel.text = getString(R.string.widget_chart_1)
                        chart2Container.visibility = View.VISIBLE
                        chart3Container.visibility = View.GONE
                        chart4Container.visibility = View.GONE
                        fieldsContainer.visibility = View.VISIBLE
                        fieldsCapHint.text = "(Max ${WidgetConfig.CAP_COMBINED_FIELDS})"
                    }
                }
            }
        }

        chartCountSpinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>?, view: View?, position: Int, id: Long) {
                updateUI()
            }
            override fun onNothingSelected(parent: android.widget.AdapterView<*>?) {}
        }

        // Limit checkbox selection based on current cap
        fun setupCheckboxListeners() {
            for ((field, cb) in checkBoxes) {
                cb.setOnCheckedChangeListener { _, isChecked ->
                    if (isChecked) {
                        val cap = if (kind == WidgetKind.SMALL) {
                            WidgetConfig.CAP_SMALL_FIELDS
                        } else {
                            val selectedMode = when (modeGroup.checkedRadioButtonId) {
                                R.id.mode_reading -> MediumMode.READING
                                R.id.mode_combined -> MediumMode.COMBINED
                                else -> MediumMode.CHART
                            }
                            if (selectedMode == MediumMode.COMBINED) WidgetConfig.CAP_COMBINED_FIELDS
                            else WidgetConfig.CAP_MEDIUM_READING_FIELDS
                        }
                        val currentlyChecked = checkBoxes.values.count { it.isChecked }
                        if (currentlyChecked > cap) {
                            cb.isChecked = false
                        }
                    }
                }
            }
        }

        if (kind == WidgetKind.MEDIUM) {
            when (existing.mode) {
                MediumMode.CHART -> modeGroup.check(R.id.mode_chart)
                MediumMode.READING -> modeGroup.check(R.id.mode_reading)
                MediumMode.COMBINED -> modeGroup.check(R.id.mode_combined)
            }
            modeGroup.setOnCheckedChangeListener { _, _ ->
                updateUI()
            }
        }

        setupCheckboxListeners()
        updateUI()

        findViewById<Button>(R.id.save_button).setOnClickListener {
            val index = serverGroup.checkedRadioButtonId
            if (index !in servers.indices) return@setOnClickListener

            val selectedMode = if (kind == WidgetKind.SMALL) {
                MediumMode.CHART
            } else {
                when (modeGroup.checkedRadioButtonId) {
                    R.id.mode_reading -> MediumMode.READING
                    R.id.mode_combined -> MediumMode.COMBINED
                    else -> MediumMode.CHART
                }
            }

            val cap = when {
                kind == WidgetKind.SMALL -> WidgetConfig.CAP_SMALL_FIELDS
                selectedMode == MediumMode.READING -> WidgetConfig.CAP_MEDIUM_READING_FIELDS
                selectedMode == MediumMode.COMBINED -> WidgetConfig.CAP_COMBINED_FIELDS
                else -> 0
            }

            val selectedFields = WidgetField.entries
                .filter { checkBoxes[it]?.isChecked == true }
                .take(cap)

            val chart1 = CHART_METRICS.getOrNull(metricSpinner.selectedItemPosition) ?: WidgetConfig.DEFAULT_CHART
            val chart2 = CHART_METRICS.getOrNull(chart2Spinner.selectedItemPosition) ?: WidgetConfig.DEFAULT_CHART2
            val chart3 = CHART_METRICS.getOrNull(chart3Spinner.selectedItemPosition) ?: WidgetConfig.DEFAULT_CHART3
            val chart4 = CHART_METRICS.getOrNull(chart4Spinner.selectedItemPosition) ?: WidgetConfig.DEFAULT_CHART4
            val count = chartCountOptions.getOrElse(chartCountSpinner.selectedItemPosition) { 1 }

            WidgetConfig.save(
                applicationContext,
                appWidgetId,
                WidgetConfig(
                    serverId = servers[index].id,
                    kind = kind,
                    mode = selectedMode,
                    fields = selectedFields,
                    chartCount = count,
                    chart = chart1,
                    chart2 = chart2,
                    chart3 = chart3,
                    chart4 = chart4,
                ),
            )

            val provider = AppWidgetManager.getInstance(applicationContext)
                .getAppWidgetInfo(appWidgetId)?.provider
            if (provider != null) {
                sendBroadcast(
                    Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                        component = provider
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                    }
                )
            }

            setResult(
                RESULT_OK,
                Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
            )
            finish()
        }
    }

    private fun buildServerList(existing: WidgetConfig): RadioGroup {
        val group = findViewById<RadioGroup>(R.id.server_group)
        servers.forEachIndexed { index, server ->
            group.addView(
                RadioButton(this).apply {
                    id = index
                    text = if (server.region != null && server.region.isNotEmpty()) {
                        "${server.name}  ·  ${server.region}"
                    } else {
                        server.name
                    }
                    isChecked = server.id == existing.serverId
                }
            )
        }
        if (group.checkedRadioButtonId !in servers.indices) group.check(0)
        return group
    }

    private fun metricLabel(metric: String): String = when (metric) {
        "cpu" -> getString(R.string.widget_metric_cpu)
        "mem" -> getString(R.string.widget_metric_memory)
        "disk" -> getString(R.string.widget_metric_disk)
        "net" -> getString(R.string.widget_metric_network)
        "load" -> getString(R.string.widget_metric_load)
        "io" -> getString(R.string.widget_metric_io)
        "conn" -> getString(R.string.widget_metric_conn)
        "proc" -> getString(R.string.widget_metric_proc)
        "loss" -> getString(R.string.widget_metric_loss)
        else -> metric.uppercase()
    }

    private fun fieldLabel(field: WidgetField): String = when (field) {
        WidgetField.CPU -> getString(R.string.widget_field_cpu)
        WidgetField.MEM -> getString(R.string.widget_field_mem)
        WidgetField.DISK -> getString(R.string.widget_field_disk)
        WidgetField.LOAD -> getString(R.string.widget_field_load)
        WidgetField.NET_SPEED -> getString(R.string.widget_field_net)
        WidgetField.NET_TOTAL -> getString(R.string.widget_field_total)
        WidgetField.TRAFFIC_LEFT -> getString(R.string.widget_field_quota)
        WidgetField.CONN -> getString(R.string.widget_field_conn)
        WidgetField.PING -> getString(R.string.widget_field_ping)
        WidgetField.LOSS -> getString(R.string.widget_field_loss)
        WidgetField.UPTIME -> getString(R.string.widget_field_uptime)
        WidgetField.EXPIRE -> getString(R.string.widget_field_expire)
    }
}

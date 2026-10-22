package app.nodepulse.widget

import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

/**
 * A widget layout may only contain classes the host can inflate.
 *
 * `RemoteViews` does not run a normal `LayoutInflater`: it inflates through
 * `RemoteViews`' own filter, which rejects anything outside a short allowlist
 * with "Class not allowed to be inflated". The failure surfaces in the
 * launcher, not in this app, and it is total — the widget never appears at
 * all, so no amount of render-path testing here would notice.
 *
 * A plain `android.view.View` was the case that got through: the 4x2 layout
 * happened never to use one, so the gap only showed up on the device when the
 * 2x4 — which draws its three dividers with one — was first placed.
 */
class WidgetLayoutClassesTest {
    /**
     * The classes `RemoteViews` permits, from its `sInflaterFilter`.
     *
     * Deliberately a list of the ones this project could plausibly reach
     * rather than the whole platform set: a tag outside it is either a
     * mistake or something that needs checking against the real filter.
     */
    private val allowed = setOf(
        "LinearLayout",
        "RelativeLayout",
        "FrameLayout",
        "GridLayout",
        "TextView",
        "Button",
        "ImageButton",
        "ImageView",
        "ProgressBar",
        "Chronometer",
        "AnalogClock",
        "TextClock",
        "ViewFlipper",
        "ViewStub",
        "AdapterViewFlipper",
        "ListView",
        "GridView",
        "StackView",
    )

    private fun layoutDir(): File {
        // Gradle runs unit tests with the module directory as the working
        // directory, which is `android/app`.
        val dir = File("src/main/res/layout")
        assertTrue("layout directory not found at ${dir.absolutePath}", dir.isDirectory)
        return dir
    }

    private fun tagsOf(file: File): List<String> {
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file)
        val nodes = doc.getElementsByTagName("*")
        return (0 until nodes.length).map { nodes.item(it).nodeName }
    }

    @Test
    fun everyWidgetLayoutUsesOnlyInflatableClasses() {
        val widgets = listOf("home_widget.xml", "home_widget_tall.xml")
        for (name in widgets) {
            val file = File(layoutDir(), name)
            assertTrue("missing widget layout $name", file.isFile)
            val rejected = tagsOf(file)
                .map { it.substringAfterLast('.') }
                .distinct()
                .filter { it !in allowed }
            assertTrue(
                "$name uses classes RemoteViews cannot inflate: $rejected",
                rejected.isEmpty(),
            )
        }
    }
}

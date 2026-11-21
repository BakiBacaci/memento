package com.bakibacaci.memento

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Günün sözü widget'ları.
 *
 * Flutter tarafı önümüzdeki 45 günün KİŞİYE ÖZEL sözlerini "days" anahtarına
 * JSON olarak yazıyor: {d: tarih, t: söz, a: yazar, bg: zemin, ink: yazı}.
 * Burada bugünün tarihine karşılık gelen söz seçiliyor; böylece uygulama hiç
 * açılmasa bile widget her gün değişir ve sözün kendi rengine bürünür.
 */
internal data class DayQuote(val text: String, val author: String, val bg: Int, val ink: Int)

internal object WidgetData {
    private val fmt get() = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    fun today(): String = fmt.format(Date())
    fun daysAgo(n: Int): String {
        val c = Calendar.getInstance(); c.add(Calendar.DAY_OF_YEAR, -n); return fmt.format(c.time)
    }

    fun color(s: String?, fallback: Int): Int = try {
        if (s.isNullOrEmpty()) fallback else Color.parseColor(s)
    } catch (_: Exception) { fallback }

    fun quoteForToday(data: SharedPreferences): DayQuote {
        val today = today()
        val lila = Color.parseColor("#C9B6FF"); val lilaInk = Color.parseColor("#2A1460")
        try {
            val days = JSONArray(data.getString("days", "[]"))
            var last: DayQuote? = null
            for (i in 0 until days.length()) {
                val o = days.getJSONObject(i)
                val q = DayQuote(o.getString("t"), o.getString("a"),
                    color(o.optString("bg"), lila), color(o.optString("ink"), lilaInk))
                if (o.getString("d") == today) return q
                if (o.getString("d") < today) last = q
            }
            if (last != null) return last
        } catch (_: Exception) {
        }
        return DayQuote(
            data.getString("text", null) ?: "Yedi kere düş, sekiz kere kalk.",
            data.getString("author", null) ?: "Japon Atasözü",
            lila, lilaInk,
        )
    }
}

/** Büyük (4x2): "Bugün senin için" + söz + yazar. */
class MementoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val q = WidgetData.quoteForToday(widgetData)
        val label = widgetData.getString("label", "Bugün senin için") ?: "Bugün senin için"
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.memento_widget).apply {
                setInt(R.id.widget_bg, "setColorFilter", q.bg)
                setTextViewText(R.id.widget_label, label)
                setTextViewText(R.id.widget_text, q.text)
                setTextViewText(R.id.widget_author, q.author)
                listOf(R.id.widget_label, R.id.widget_brand, R.id.widget_text, R.id.widget_author)
                    .forEach { setTextColor(it, q.ink) }
                // Uzun sözlerde yazı küçülür, kısa sözler kocaman durur.
                setTextViewTextSize(R.id.widget_text, android.util.TypedValue.COMPLEX_UNIT_SP,
                    when { q.text.length > 120 -> 15f; q.text.length > 70 -> 18f; else -> 22f })
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}

/** Küçük (2x2): yalnızca söz. */
class MementoSmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val q = WidgetData.quoteForToday(widgetData)
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.memento_widget_small).apply {
                setInt(R.id.widget_bg, "setColorFilter", q.bg)
                setTextViewText(R.id.widget_text, q.text)
                setTextColor(R.id.widget_text, q.ink)
                setTextColor(R.id.widget_brand, q.ink)
                setTextViewTextSize(R.id.widget_text, android.util.TypedValue.COMPLEX_UNIT_SP,
                    when { q.text.length > 90 -> 13f; q.text.length > 50 -> 15f; else -> 18f })
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}

/**
 * Defter (2x2): seri + son 7 günün renk şeridi.
 *
 * Flutter "journal" anahtarına deftere yazılan günleri yazar: [{d, c}].
 * Seri burada her çizimde yeniden hesaplanır; uygulama açılmasa da gece
 * yarısından sonra doğru görünür (dün yazılmadıysa seri sıfır).
 */
class MementoJournalWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val en = (widgetData.getString("lang", "tr") ?: "tr") == "en"
        val colors = HashMap<String, Int>()
        try {
            val arr = JSONArray(widgetData.getString("journal", "[]"))
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                colors[o.getString("d")] = WidgetData.color(o.optString("c"), Color.parseColor("#C9B6FF"))
            }
        } catch (_: Exception) {
        }
        val todayDone = colors.containsKey(WidgetData.today())
        var n = 0
        var k = if (todayDone) 0 else 1
        while (colors.containsKey(WidgetData.daysAgo(k))) { n++; k++ }

        val cells = intArrayOf(R.id.c0, R.id.c1, R.id.c2, R.id.c3, R.id.c4, R.id.c5, R.id.c6)
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.memento_journal_widget).apply {
                setInt(R.id.widget_bg, "setColorFilter", Color.parseColor("#151517"))
                setTextViewText(R.id.j_label, if (en) "Your journal" else "Defterin")
                setTextViewText(R.id.j_streak, if (n > 0) "🔥 $n" else "0")
                setTextViewText(R.id.j_sub, when {
                    !todayDone && n > 0 -> if (en) "write today to keep it" else "bugün yaz, seri sürsün"
                    !todayDone -> if (en) "today's page is empty" else "bugünün sayfası boş"
                    else -> if (en) "days in a row" else "gün üst üste"
                })
                // Son 7 gün: soldan eskiden yeniye. Yazılan gün o günün sözünün renginde.
                for (i in 0 until 7) {
                    val c = colors[WidgetData.daysAgo(6 - i)]
                    if (c != null) {
                        setImageViewResource(cells[i], R.drawable.widget_cell)
                        setInt(cells[i], "setColorFilter", c)
                    } else {
                        setImageViewResource(cells[i], R.drawable.widget_cell_empty)
                        setInt(cells[i], "setColorFilter", Color.TRANSPARENT)
                    }
                }
                setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}

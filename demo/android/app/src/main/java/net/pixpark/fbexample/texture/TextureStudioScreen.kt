package net.pixpark.fbexample.texture

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Cameraswitch
import androidx.compose.material.icons.outlined.IosShare
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import net.pixpark.fbexample.AppLocale
import net.pixpark.fbexample.beauty.BeautyPanel
import kotlin.math.roundToInt

@Composable
fun TextureStudioScreen(
    locale: AppLocale,
    onClose: () -> Unit,
    onStopped: () -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val session = remember { TextureStudioSession(context, locale) }

    DisposableEffect(session) {
        session.start()
        onDispose {
            session.stop()
            onStopped()
        }
    }

    BackHandler {
        session.stop()
        onClose()
    }

    MaterialTheme(colorScheme = darkColorScheme()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
        ) {
            AndroidView(
                factory = { viewContext ->
                    TexturePreviewView(viewContext).also { preview ->
                        session.attach(preview, lifecycleOwner)
                    }
                },
                modifier = Modifier.fillMaxSize(),
            )

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Black.copy(0.55f), Color.Transparent, Color.Black.copy(0.72f)),
                        ),
                    )
                    .statusBarsPadding()
                    .navigationBarsPadding(),
            ) {
                TopBar(
                    session = session,
                    onClose = {
                        session.stop()
                        onClose()
                    },
                )
                Hud(session)
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .pointerInput(Unit) {
                            awaitEachGesture {
                                awaitFirstDown()
                                session.setCompareMode(true)
                                waitForUpOrCancellation()
                                session.setCompareMode(false)
                            }
                        },
                )
                if (session.statusKey.isNotEmpty()) {
                    StatusChip(
                        text = if (session.isComparing) {
                            session.t("preview.original")
                        } else {
                            session.t(session.statusKey)
                        },
                        comparing = session.isComparing,
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(bottom = 8.dp),
                    )
                }
                if (!session.isComparing) {
                    Row(
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(bottom = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        HintChip(session.t("preview.hold"))
                        if (session.panelExpanded) {
                            HintChip(session.t("preview.collapseHint"))
                        }
                    }
                }
                BeautyPanel(session)
            }
        }
    }
}

@Composable
private fun TopBar(
    session: TextureStudioSession,
    onClose: () -> Unit,
) {
    var languageOpen by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 12.dp, end = 12.dp, top = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        TopIcon(
            Icons.AutoMirrored.Outlined.ArrowBack,
            session.t("nav.close"),
            modifier = Modifier.weight(1f),
            onClick = onClose,
        )
        TopIcon(
            Icons.Outlined.Cameraswitch,
            session.t("nav.flip"),
            modifier = Modifier.weight(1f),
            onClick = { session.flipCamera() },
        )
        TopIcon(
            Icons.Outlined.Refresh,
            session.t("nav.reset"),
            modifier = Modifier.weight(1f),
            onClick = { session.reset() },
        )
        TopIcon(
            Icons.Outlined.IosShare,
            session.t("nav.export"),
            modifier = Modifier.weight(1f),
            onClick = { session.capture() },
        )
        Box(modifier = Modifier.weight(1f)) {
            TopIcon(
                Icons.Outlined.Language,
                session.locale.shortLabel,
                active = true,
                modifier = Modifier.fillMaxWidth(),
                onClick = { languageOpen = true },
            )
            DropdownMenu(expanded = languageOpen, onDismissRequest = { languageOpen = false }) {
                AppLocale.entries.forEach { item ->
                    DropdownMenuItem(
                        text = { Text(item.shortLabel) },
                        onClick = {
                            session.updateLocale(item)
                            languageOpen = false
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun TopIcon(
    icon: ImageVector,
    title: String,
    active: Boolean = false,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Surface(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = if (active) Color.White else Color.White.copy(0.10f),
        contentColor = if (active) Color.Black else Color.White,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .height(46.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp, Alignment.CenterVertically),
        ) {
            Icon(icon, contentDescription = title, modifier = Modifier.size(15.dp))
            Text(title, fontSize = 10.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

@Composable
private fun Hud(session: TextureStudioSession) {
    Column(
        modifier = Modifier
            .padding(horizontal = 12.dp, vertical = 6.dp)
            .fillMaxWidth()
            .background(Color.Black.copy(0.35f), RoundedCornerShape(12.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = session.t("texture.title"),
            color = Color.White.copy(0.9f),
            fontSize = 12.sp,
        )
        Text(
            text = session.t("texture.subtitle"),
            color = Color.White.copy(0.7f),
            fontSize = 11.sp,
        )
        if (session.fps > 0) {
            Text(
                text = "${session.fps.roundToInt()} FPS",
                color = Color.White.copy(0.7f),
                fontSize = 11.sp,
            )
        }
    }
}

@Composable
private fun HintChip(text: String) {
    Text(
        text = text,
        color = Color.White.copy(0.55f),
        fontSize = 11.sp,
        modifier = Modifier
            .background(Color.Black.copy(0.35f), RoundedCornerShape(50))
            .padding(horizontal = 10.dp, vertical = 5.dp),
    )
}

@Composable
private fun StatusChip(text: String, comparing: Boolean, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .background(Color.Black.copy(0.55f), RoundedCornerShape(50))
            .padding(horizontal = 12.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .background(if (comparing) Color.Gray else Color(0xFF22C55E), RoundedCornerShape(50)),
        )
        Text(text, color = Color.White, fontSize = 12.sp)
    }
}

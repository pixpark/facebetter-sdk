package net.pixpark.fbexample.studio

import android.graphics.Bitmap
import android.widget.ImageView
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Cameraswitch
import androidx.compose.material.icons.outlined.IosShare
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Layers
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Videocam
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import net.pixpark.fbexample.AppLocale
import net.pixpark.fbexample.beauty.BeautyPanel
import kotlin.math.roundToInt

@Composable
fun StudioScreen(
    viewModel: StudioViewModel,
    onPickImage: () -> Unit,
    onStartCamera: () -> Unit,
    onFlipCamera: () -> Unit,
    onOpenTexture: () -> Unit,
    onFinish: () -> Unit,
) {
    BackHandler {
        if (viewModel.panelExpanded) {
            viewModel.panelExpanded = false
        } else {
            onFinish()
        }
    }

    MaterialTheme(colorScheme = darkColorScheme()) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
        ) {
            PreviewPane(
                bitmap = viewModel.previewBitmap,
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(Unit) {
                        awaitEachGesture {
                            awaitFirstDown()
                            viewModel.setCompareMode(true)
                            waitForUpOrCancellation()
                            viewModel.setCompareMode(false)
                        }
                    },
            )

            // The watermark sits at about 85% of the frame. A gradient across the lower half would gray out the white mark.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            0f to Color.Black.copy(0.55f),
                            0.18f to Color.Transparent,
                            0.90f to Color.Transparent,
                            1f to Color.Black.copy(0.55f),
                        ),
                    ),
            )

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .statusBarsPadding()
                    .navigationBarsPadding(),
            ) {
                TopBar(
                    viewModel = viewModel,
                    onPickImage = onPickImage,
                    onStartCamera = onStartCamera,
                    onFlipCamera = onFlipCamera,
                    onOpenTexture = onOpenTexture,
                )
                FpsBadge(
                    viewModel = viewModel,
                    modifier = Modifier
                        .align(Alignment.End)
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                )
                if (!viewModel.isComparing) {
                    HintChip(
                        viewModel.t("preview.hold"),
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(top = 10.dp),
                    )
                }
                Spacer(modifier = Modifier.weight(1f))
                if (viewModel.statusKey.isNotEmpty()) {
                    StatusChip(
                        text = if (viewModel.isComparing) {
                            viewModel.t("preview.original")
                        } else {
                            viewModel.t(viewModel.statusKey)
                        },
                        comparing = viewModel.isComparing,
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(bottom = 8.dp),
                    )
                }
                BeautyPanel(viewModel = viewModel)
            }
        }
    }
}

@Composable
private fun PreviewPane(bitmap: Bitmap?, modifier: Modifier = Modifier) {
    AndroidView(
        factory = { context ->
            ImageView(context).apply {
                scaleType = ImageView.ScaleType.FIT_CENTER
                setBackgroundColor(android.graphics.Color.BLACK)
            }
        },
        update = { view ->
            if (bitmap != null) {
                view.setImageBitmap(bitmap)
            }
        },
        modifier = modifier,
    )
}

@Composable
private fun TopBar(
    viewModel: StudioViewModel,
    onPickImage: () -> Unit,
    onStartCamera: () -> Unit,
    onFlipCamera: () -> Unit,
    onOpenTexture: () -> Unit,
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
            Icons.Outlined.PhotoLibrary,
            viewModel.t("nav.gallery"),
            modifier = Modifier.weight(1f),
            onClick = onPickImage,
        )
        if (viewModel.source == StudioSource.IMAGE) {
            TopIcon(
                Icons.Outlined.Videocam,
                viewModel.t("nav.camera"),
                active = true,
                modifier = Modifier.weight(1f),
                onClick = onStartCamera,
            )
        } else {
            TopIcon(
                Icons.Outlined.Cameraswitch,
                viewModel.t("nav.flip"),
                modifier = Modifier.weight(1f),
                onClick = onFlipCamera,
            )
        }
        TopIcon(
            Icons.Outlined.Refresh,
            viewModel.t("nav.reset"),
            modifier = Modifier.weight(1f),
            onClick = { viewModel.reset() },
        )
        TopIcon(
            Icons.Outlined.IosShare,
            viewModel.t("nav.export"),
            modifier = Modifier.weight(1f),
            onClick = { viewModel.capture() },
        )
        TopIcon(
            Icons.Outlined.Layers,
            viewModel.t("nav.texture"),
            modifier = Modifier.weight(1f),
            onClick = onOpenTexture,
        )
        Box(modifier = Modifier.weight(1f)) {
            TopIcon(
                Icons.Outlined.Language,
                viewModel.locale.shortLabel,
                active = true,
                modifier = Modifier.fillMaxWidth(),
                onClick = { languageOpen = true },
            )
            DropdownMenu(expanded = languageOpen, onDismissRequest = { languageOpen = false }) {
                AppLocale.entries.forEach { item ->
                    DropdownMenuItem(
                        text = { Text(item.shortLabel) },
                        onClick = {
                            viewModel.updateLocale(item)
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
    icon: androidx.compose.ui.graphics.vector.ImageVector,
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
private fun FpsBadge(viewModel: StudioViewModel, modifier: Modifier = Modifier) {
    if (viewModel.source != StudioSource.CAMERA || viewModel.fps <= 0) {
        return
    }
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .background(
                        if (viewModel.fps > 25) Color(0xFF22C55E) else Color(0xFFF97316),
                        RoundedCornerShape(50),
                    ),
            )
            Text(
                text = "${viewModel.fps.roundToInt()} FPS",
                color = Color.White.copy(0.7f),
                fontSize = 11.sp,
            )
        }
        if (viewModel.processMs > 0) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Box(
                    modifier = Modifier
                        .size(6.dp)
                        .background(latencyColor(viewModel.processMs), RoundedCornerShape(50)),
                )
                Text(
                    text = "${viewModel.processMs.roundToInt()} ms",
                    color = Color.White.copy(0.7f),
                    fontSize = 11.sp,
                )
            }
        }
    }
}

private fun latencyColor(ms: Double): Color = when {
    ms > 60.0 -> Color(0xFFEF4444)
    ms < 30.0 -> Color(0xFF22C55E)
    else -> Color(0xFFF97316)
}

@Composable
private fun HintChip(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        color = Color.White.copy(0.55f),
        fontSize = 11.sp,
        modifier = modifier
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

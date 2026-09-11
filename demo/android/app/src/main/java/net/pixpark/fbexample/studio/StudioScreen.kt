package net.pixpark.fbexample.studio

import android.graphics.Bitmap
import android.widget.ImageView
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
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
import androidx.compose.material.icons.outlined.FilterCenterFocus
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import net.pixpark.facebetter.FaceDetectionResult
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

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Black.copy(0.55f), Color.Transparent, Color.Black.copy(0.72f)),
                        ),
                    ),
            )

            if (viewModel.showLandmarks && !viewModel.isComparing) {
                LandmarkOverlay(
                    faces = viewModel.faces,
                    imageWidth = viewModel.previewBitmap?.width ?: 0,
                    imageHeight = viewModel.previewBitmap?.height ?: 0,
                    modifier = Modifier.fillMaxSize(),
                )
            }

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
                if (!viewModel.isComparing) {
                    Row(
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(bottom = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        HintChip(viewModel.t("preview.hold"))
                        if (viewModel.panelExpanded) {
                            HintChip(viewModel.t("preview.collapseHint"))
                        }
                    }
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
            Icons.Outlined.FilterCenterFocus,
            viewModel.t("nav.landmarks"),
            active = viewModel.showLandmarks,
            modifier = Modifier.weight(1f),
            onClick = { viewModel.showLandmarks = !viewModel.showLandmarks },
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
    Row(
        modifier = modifier
            .background(Color.Black.copy(0.35f), RoundedCornerShape(50))
            .padding(horizontal = 8.dp, vertical = 4.dp),
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

@Composable
private fun LandmarkOverlay(
    faces: List<FaceDetectionResult>,
    imageWidth: Int,
    imageHeight: Int,
    modifier: Modifier = Modifier,
) {
    Canvas(modifier = modifier) {
        val content = aspectFitRect(
            imageWidth = imageWidth.toFloat(),
            imageHeight = imageHeight.toFloat(),
            viewWidth = size.width,
            viewHeight = size.height,
        )
        if (content.width <= 0f || content.height <= 0f) {
            return@Canvas
        }
        faces.forEach { face ->
            val rect = face.rect ?: return@forEach
            drawRect(
                color = Color.White.copy(0.7f),
                topLeft = Offset(
                    content.left + rect.x * content.width,
                    content.top + rect.y * content.height,
                ),
                size = Size(rect.width * content.width, rect.height * content.height),
                style = Stroke(width = 1.dp.toPx()),
            )
            val points = face.keyPoints ?: return@forEach
            val visibility = face.visibility
            points.forEachIndexed { index, point ->
                if (visibility != null && index < visibility.size && visibility[index] < 0.4f) {
                    return@forEachIndexed
                }
                drawCircle(
                    color = Color.White,
                    radius = 1.2.dp.toPx(),
                    center = Offset(
                        content.left + point.x * content.width,
                        content.top + point.y * content.height,
                    ),
                )
            }
        }
    }
}

private data class ContentRect(
    val left: Float,
    val top: Float,
    val width: Float,
    val height: Float,
)

private fun aspectFitRect(
    imageWidth: Float,
    imageHeight: Float,
    viewWidth: Float,
    viewHeight: Float,
): ContentRect {
    if (imageWidth <= 0f || imageHeight <= 0f || viewWidth <= 0f || viewHeight <= 0f) {
        return ContentRect(0f, 0f, 0f, 0f)
    }
    val scale = minOf(viewWidth / imageWidth, viewHeight / imageHeight)
    val width = imageWidth * scale
    val height = imageHeight * scale
    return ContentRect(
        left = (viewWidth - width) / 2f,
        top = (viewHeight - height) / 2f,
        width = width,
        height = height,
    )
}

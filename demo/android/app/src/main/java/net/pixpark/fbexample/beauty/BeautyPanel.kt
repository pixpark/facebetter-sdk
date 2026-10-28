package net.pixpark.fbexample.beauty

import android.graphics.BitmapFactory
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Accessibility
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Brush
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Face
import androidx.compose.material.icons.outlined.FilterVintage
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.Spa
import androidx.compose.material.icons.outlined.Wallpaper
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

private val Brand = Color(0xFF10B981)
private val ChipShape = RoundedCornerShape(12.dp)
private val FilterRowHeight = 44.dp
private val FilterRowSpacing = 8.dp

@Composable
fun BeautyPanel(viewModel: BeautySession) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Color.Black.copy(0.82f),
                RoundedCornerShape(topStart = 18.dp, topEnd = 18.dp),
            ),
    ) {
        AnimatedVisibility(
            visible = viewModel.panelExpanded,
            enter = expandVertically(),
            exit = shrinkVertically(),
        ) {
            Column(
                modifier = Modifier.padding(top = 10.dp, bottom = 6.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                when (viewModel.tab) {
                    BeautyTab.SKIN -> SkinSection(viewModel)
                    BeautyTab.RESHAPE -> ReshapeSection(viewModel)
                    BeautyTab.BODY -> BodySection(viewModel)
                    BeautyTab.MAKEUP -> MakeupSection(viewModel)
                    BeautyTab.FILTER -> FilterSection(viewModel)
                    BeautyTab.STICKER -> StickerSection(viewModel)
                    BeautyTab.BACKGROUND -> BackgroundSection(viewModel)
                }
            }
        }
        TabBar(
            viewModel,
            modifier = Modifier.padding(
                top = if (viewModel.panelExpanded) 4.dp else 10.dp,
                bottom = 10.dp,
            ),
        )
    }
}

@Composable
private fun TabBar(viewModel: BeautySession, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 6.dp),
    ) {
        BeautyTab.entries.forEach { item ->
            val selected = viewModel.tab == item && viewModel.panelExpanded
            val tint = if (selected) Brand else Color.White.copy(0.75f)
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                    ) {
                        if (viewModel.tab == item && viewModel.panelExpanded) {
                            viewModel.panelExpanded = false
                        } else {
                            viewModel.tab = item
                            viewModel.panelExpanded = true
                        }
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Icon(
                    item.icon,
                    contentDescription = viewModel.t(item.labelKey),
                    modifier = Modifier.size(18.dp),
                    tint = tint,
                )
                Text(
                    viewModel.t(item.labelKey),
                    color = tint,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Box(
                    modifier = Modifier
                        .width(16.dp)
                        .height(2.dp)
                        .background(if (selected) Brand else Color.Transparent, CircleShape),
                )
            }
        }
    }
}

private val BeautyTab.icon: ImageVector
    get() = when (this) {
        BeautyTab.SKIN -> Icons.Outlined.Spa
        BeautyTab.RESHAPE -> Icons.Outlined.Face
        BeautyTab.BODY -> Icons.Outlined.Accessibility
        BeautyTab.MAKEUP -> Icons.Outlined.Brush
        BeautyTab.FILTER -> Icons.Outlined.FilterVintage
        BeautyTab.STICKER -> Icons.Outlined.AutoAwesome
        BeautyTab.BACKGROUND -> Icons.Outlined.Wallpaper
    }

@Composable
private fun SkinSection(viewModel: BeautySession) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SliderRow(
            title = viewModel.t(viewModel.selectedSkin.labelKey),
            value = viewModel.params.skinIntensity(viewModel.selectedSkin),
            onValueChange = { viewModel.updateParams { setSkinIntensity(viewModel.selectedSkin, it) } },
            onReset = { viewModel.updateParams { resetSkin() } },
            resetLabel = viewModel.t("nav.reset"),
        ) {
            CheckBox(
                title = viewModel.t("skin.skinOnly"),
                checked = viewModel.params.skinOnly,
                onClick = { viewModel.updateParams { copy(skinOnly = !skinOnly) } },
            )
        }
        SecondaryTabBar(
            titles = SkinItem.entries.map { viewModel.t(it.labelKey) },
            selected = SkinItem.entries.indexOf(viewModel.selectedSkin).coerceAtLeast(0),
            onSelect = { viewModel.selectedSkin = SkinItem.entries[it] },
        )
        if (viewModel.selectedSkin == SkinItem.SMOOTHING) {
            ChipRow {
                BeautyCatalog.smoothingStyles.forEach { item ->
                    TextChip(
                        title = viewModel.t(item.labelKey),
                        selected = viewModel.params.smoothingStyle == item.id,
                        onClick = { viewModel.updateParams { copy(smoothingStyle = item.id) } },
                    )
                }
            }
        } else if (viewModel.selectedSkin == SkinItem.WHITENING) {
            ChipRow {
                BeautyCatalog.whiteningStyles.forEach { item ->
                    TextChip(
                        title = viewModel.t(item.labelKey),
                        selected = viewModel.params.whiteningStyle == item.id,
                        onClick = { viewModel.updateParams { copy(whiteningStyle = item.id) } },
                    )
                }
            }
        }
    }
}

@Composable
private fun ReshapeSection(viewModel: BeautySession) {
    var groupId by remember {
        mutableStateOf(
            BeautyCatalog.reshapeGroups.firstOrNull { group ->
                group.items.any { it.key == viewModel.selectedReshape }
            }?.id ?: BeautyCatalog.reshapeGroups.first().id,
        )
    }
    val group = BeautyCatalog.reshapeGroups.firstOrNull { it.id == groupId }
        ?: BeautyCatalog.reshapeGroups.first()
    val title = BeautyCatalog.reshapeItems.firstOrNull { it.key == viewModel.selectedReshape }?.labelKey
        ?: "reshape.faceThin"
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SliderRow(
            title = viewModel.t(title),
            value = viewModel.params.reshape[viewModel.selectedReshape] ?: 0f,
            onValueChange = { next ->
                viewModel.updateParams {
                    copy(reshape = reshape.toMutableMap().apply { put(viewModel.selectedReshape, next) })
                }
            },
            onReset = { viewModel.updateParams { resetReshape() } },
            resetLabel = viewModel.t("nav.reset"),
            signed = true,
            valueRange = -1f..1f,
        )
        SecondaryTabBar(
            titles = BeautyCatalog.reshapeGroups.map { viewModel.t("reshape.${it.id}") },
            selected = BeautyCatalog.reshapeGroups.indexOfFirst { it.id == group.id }.coerceAtLeast(0),
            onSelect = { index ->
                val next = BeautyCatalog.reshapeGroups[index]
                groupId = next.id
                if (next.items.none { it.key == viewModel.selectedReshape }) {
                    next.items.firstOrNull()?.let { viewModel.selectedReshape = it.key }
                }
            },
        )
        ChipRow {
            group.items.forEach { item ->
                TextChip(
                    title = viewModel.t(item.labelKey),
                    selected = viewModel.selectedReshape == item.key,
                    onClick = { viewModel.selectedReshape = item.key },
                )
            }
        }
    }
}

@Composable
private fun BodySection(viewModel: BeautySession) {
    var groupId by remember {
        mutableStateOf(
            BeautyCatalog.bodyGroups.firstOrNull { group ->
                group.items.any { it.key == viewModel.selectedBody }
            }?.id ?: BeautyCatalog.bodyGroups.first().id,
        )
    }
    val group = BeautyCatalog.bodyGroups.firstOrNull { it.id == groupId }
        ?: BeautyCatalog.bodyGroups.first()
    val title = BeautyCatalog.bodyItems.firstOrNull { it.key == viewModel.selectedBody }?.labelKey
        ?: "reshape.bodySlim"
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SliderRow(
            title = viewModel.t(title),
            value = viewModel.params.bodyReshape[viewModel.selectedBody] ?: 0f,
            onValueChange = { next ->
                viewModel.updateParams {
                    copy(bodyReshape = bodyReshape.toMutableMap().apply { put(viewModel.selectedBody, next) })
                }
            },
            onReset = { viewModel.updateParams { resetBody() } },
            resetLabel = viewModel.t("nav.reset"),
        )
        SecondaryTabBar(
            titles = BeautyCatalog.bodyGroups.map { viewModel.t("reshape.${it.id}") },
            selected = BeautyCatalog.bodyGroups.indexOfFirst { it.id == group.id }.coerceAtLeast(0),
            onSelect = { index ->
                val next = BeautyCatalog.bodyGroups[index]
                groupId = next.id
                if (next.items.none { it.key == viewModel.selectedBody }) {
                    next.items.firstOrNull()?.let { viewModel.selectedBody = it.key }
                }
            },
        )
        ChipRow {
            group.items.forEach { item ->
                TextChip(
                    title = viewModel.t(item.labelKey),
                    selected = viewModel.selectedBody == item.key,
                    onClick = { viewModel.selectedBody = item.key },
                )
            }
        }
    }
}

@Composable
private fun MakeupSection(viewModel: BeautySession) {
    val styles = when (viewModel.selectedMakeup) {
        MakeupItem.BLUSH -> BeautyCatalog.blushStyles
        MakeupItem.CONTOUR -> BeautyCatalog.contourStyles
        MakeupItem.EYESHADOW -> BeautyCatalog.eyeshadowStyles
        MakeupItem.EYELINER -> BeautyCatalog.eyelinerStyles
        MakeupItem.EYEBROW -> BeautyCatalog.eyebrowStyles
        MakeupItem.EYELASH -> BeautyCatalog.eyelashStyles
        else -> emptyList()
    }
    val colors = when (viewModel.selectedMakeup) {
        MakeupItem.LIPSTICK -> BeautyCatalog.lipstickColors
        MakeupItem.BLUSH -> BeautyCatalog.blushColors
        MakeupItem.EYESHADOW -> BeautyCatalog.eyeshadowColors
        MakeupItem.EYELINER -> BeautyCatalog.eyelinerColors
        MakeupItem.EYEBROW -> BeautyCatalog.eyebrowColors
        MakeupItem.EYELASH -> BeautyCatalog.eyelashColors
        MakeupItem.PUPIL -> BeautyCatalog.pupilColors
        MakeupItem.CONTOUR, MakeupItem.TEETH -> emptyList()
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SliderRow(
            title = viewModel.t("makeup.intensity"),
            value = viewModel.params.intensity(viewModel.selectedMakeup),
            onValueChange = { viewModel.updateParams { setIntensity(viewModel.selectedMakeup, it) } },
            onReset = { viewModel.updateParams { resetMakeup() } },
            resetLabel = viewModel.t("nav.reset"),
        )
        SecondaryTabBar(
            titles = MakeupItem.entries.map { viewModel.t(it.labelKey) },
            selected = MakeupItem.entries.indexOf(viewModel.selectedMakeup).coerceAtLeast(0),
            onSelect = { viewModel.selectedMakeup = MakeupItem.entries[it] },
        )
        if (viewModel.selectedMakeup == MakeupItem.TEETH) {
            ChipRow {
                TextChip(title = viewModel.t("makeup.teethWhiten"), selected = true, onClick = {})
            }
        } else if (styles.isNotEmpty()) {
            ChipRow {
                styles.forEach { item ->
                    TextChip(
                        title = viewModel.t(item.labelKey),
                        selected = makeupStyleSelected(viewModel, item.id),
                        onClick = { applyMakeupStyle(viewModel, item.id) },
                    )
                }
            }
        }
        if (colors.isNotEmpty()) {
            ColorRow {
                colors.forEach { item ->
                    ColorDot(
                        color = item.color ?: Color.White,
                        selected = makeupColorSelected(viewModel, item.id),
                        onClick = { applyMakeupColor(viewModel, item.id) },
                    )
                }
            }
        }
    }
}

private enum class FilterPage { LOOK, ADJUST }

private enum class AdjustItem(val labelKey: String) {
    BRIGHTNESS("color.brightness"),
    CONTRAST("color.contrast"),
    SATURATION("color.saturation"),
    TEMPERATURE("color.temperature"),
    TINT("color.tint"),
}

@Composable
private fun FilterSection(viewModel: BeautySession) {
    var page by remember { mutableStateOf(FilterPage.LOOK) }
    var adjust by remember { mutableStateOf(AdjustItem.BRIGHTNESS) }
    val adjustValue = when (adjust) {
        AdjustItem.BRIGHTNESS -> viewModel.params.brightness
        AdjustItem.CONTRAST -> viewModel.params.contrast
        AdjustItem.SATURATION -> viewModel.params.saturation
        AdjustItem.TEMPERATURE -> viewModel.params.colorTemperature
        AdjustItem.TINT -> viewModel.params.colorTint
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (page == FilterPage.LOOK) {
            SliderRow(
                title = viewModel.t("filter.intensity"),
                value = viewModel.params.filterIntensity,
                onValueChange = { viewModel.updateParams { copy(filterIntensity = it) } },
                onReset = { viewModel.updateParams { resetColor() } },
                resetLabel = viewModel.t("nav.reset"),
                enabled = viewModel.params.filterId != null,
            )
        } else {
            SliderRow(
                title = viewModel.t(adjust.labelKey),
                value = adjustValue,
                onValueChange = { next ->
                    viewModel.updateParams {
                        when (adjust) {
                            AdjustItem.BRIGHTNESS -> copy(brightness = next)
                            AdjustItem.CONTRAST -> copy(contrast = next)
                            AdjustItem.SATURATION -> copy(saturation = next)
                            AdjustItem.TEMPERATURE -> copy(colorTemperature = next)
                            AdjustItem.TINT -> copy(colorTint = next)
                        }
                    }
                },
                onReset = { viewModel.updateParams { resetColor() } },
                resetLabel = viewModel.t("nav.reset"),
                signed = true,
                valueRange = -1f..1f,
            )
        }
        SecondaryTabBar(
            titles = listOf(viewModel.t("color.group.filter"), viewModel.t("color.group.adjust")),
            selected = if (page == FilterPage.LOOK) 0 else 1,
            onSelect = { page = if (it == 0) FilterPage.LOOK else FilterPage.ADJUST },
        )
        if (page == FilterPage.LOOK) {
            FilterGrid(viewModel)
        } else {
            ChipRow {
                AdjustItem.entries.forEach { item ->
                    TextChip(
                        title = viewModel.t(item.labelKey),
                        selected = adjust == item,
                        onClick = { adjust = item },
                    )
                }
            }
        }
    }
}

@Composable
private fun FilterGrid(viewModel: BeautySession) {
    val ids = listOf<String?>(null) + BeautyCatalog.filterIds
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        modifier = Modifier
            .fillMaxWidth()
            .height(FilterRowHeight * 3 + FilterRowSpacing * 2)
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(ids, key = { it ?: "none" }) { id ->
            TextChip(
                title = if (id == null) viewModel.t("filter.none") else viewModel.filterLabel(id),
                selected = viewModel.params.filterId == id,
                fillsWidth = true,
                onClick = { viewModel.updateParams { copy(filterId = id) } },
            )
        }
    }
}

@Composable
private fun StickerSection(viewModel: BeautySession) {
    val kinds = StickerKind.entries.filter { kind ->
        BeautyCatalog.stickers.any { it.kind == kind }
    }
    var kind by remember {
        val current = viewModel.params.stickerId?.let { id -> BeautyCatalog.sticker(id)?.kind }
        mutableStateOf(current ?: kinds.first())
    }
    LaunchedEffect(viewModel.params.stickerId) {
        val id = viewModel.params.stickerId ?: return@LaunchedEffect
        BeautyCatalog.sticker(id)?.let { kind = it.kind }
    }
    val items = BeautyCatalog.stickers.filter { it.kind == kind }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            ResetButton(
                label = viewModel.t("nav.reset"),
                onClick = { viewModel.updateParams { resetSticker() } },
                modifier = Modifier.padding(start = 12.dp),
            )
        }
        SecondaryTabBar(
            titles = kinds.map { viewModel.t(it.titleKey) },
            selected = kinds.indexOf(kind).coerceAtLeast(0),
            onSelect = { kind = kinds[it] },
        )
        ChipRow {
            TextChip(
                title = viewModel.t("sticker.none"),
                selected = viewModel.params.stickerId == null,
                onClick = { viewModel.updateParams { copy(stickerId = null) } },
            )
            items.forEach { item ->
                TextChip(
                    title = viewModel.t("sticker.${item.id}"),
                    selected = viewModel.params.stickerId == item.id,
                    badge = if (item.animated) viewModel.t("sticker.tag.animated") else null,
                    onClick = { viewModel.updateParams { copy(stickerId = item.id) } },
                )
            }
        }
    }
}

private enum class BgPage { SCENE, CUTOUT }

private enum class ChromaParam(val labelKey: String) {
    SIMILARITY("bg.similarity"),
    SMOOTHNESS("bg.smoothness"),
    DESATURATION("bg.desaturation"),
}

@Composable
private fun BackgroundSection(viewModel: BeautySession) {
    var page by remember { mutableStateOf(BgPage.SCENE) }
    var chromaParam by remember { mutableStateOf(ChromaParam.SIMILARITY) }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (page == BgPage.SCENE) {
            SliderRow(
                title = viewModel.t("bg.blurAmount"),
                value = viewModel.params.bgBlur,
                onValueChange = { viewModel.updateParams { copy(bgBlur = it) } },
                onReset = { viewModel.updateParams { resetBackground() } },
                resetLabel = viewModel.t("nav.reset"),
                enabled = viewModel.params.backgroundFill == BackgroundFill.BLUR,
            ) {
                CheckBox(
                    title = viewModel.t("bg.outline"),
                    checked = viewModel.params.subjectOutline,
                    onClick = { viewModel.updateParams { copy(subjectOutline = !subjectOutline) } },
                )
            }
        } else if (viewModel.params.chroma != null) {
            val value = when (chromaParam) {
                ChromaParam.SIMILARITY -> viewModel.params.chromaSimilarity
                ChromaParam.SMOOTHNESS -> viewModel.params.chromaSmoothness
                ChromaParam.DESATURATION -> viewModel.params.chromaDesaturation
            }
            SliderRow(
                title = viewModel.t(chromaParam.labelKey),
                value = value,
                onValueChange = { next ->
                    viewModel.updateParams {
                        when (chromaParam) {
                            ChromaParam.SIMILARITY -> copy(chromaSimilarity = next)
                            ChromaParam.SMOOTHNESS -> copy(chromaSmoothness = next)
                            ChromaParam.DESATURATION -> copy(chromaDesaturation = next)
                        }
                    }
                },
                onReset = { viewModel.updateParams { resetBackground() } },
                resetLabel = viewModel.t("nav.reset"),
            )
        } else {
            SliderRow(
                title = viewModel.t("bg.portrait"),
                value = 0f,
                onValueChange = {},
                onReset = { viewModel.updateParams { resetBackground() } },
                resetLabel = viewModel.t("nav.reset"),
                enabled = false,
            )
        }
        SecondaryTabBar(
            titles = listOf(viewModel.t("tab.background"), viewModel.t("bg.cutout")),
            selected = if (page == BgPage.SCENE) 0 else 1,
            onSelect = { page = if (it == 0) BgPage.SCENE else BgPage.CUTOUT },
        )
        ChipRow {
            if (page == BgPage.SCENE) {
                BackgroundFill.entries.forEach { fill ->
                    TextChip(
                        title = viewModel.t(fill.labelKey),
                        selected = viewModel.params.backgroundFill == fill,
                        onClick = {
                            viewModel.updateParams {
                                val preset = if (fill == BackgroundFill.IMAGE && bgPreset == null) {
                                    BeautyCatalog.backgroundPresets.firstOrNull()?.id
                                } else {
                                    bgPreset
                                }
                                copy(backgroundFill = fill, bgPreset = preset)
                            }
                        },
                    )
                }
            } else {
                TextChip(
                    title = viewModel.t("bg.portrait"),
                    selected = viewModel.params.chroma == null,
                    onClick = { viewModel.updateParams { copy(chroma = null) } },
                )
                BeautyCatalog.chromaOptions.forEach { option ->
                    ColorChip(
                        color = option.color ?: Color.White,
                        selected = viewModel.params.chroma == option.id,
                        onClick = { viewModel.updateParams { copy(chroma = option.id) } },
                    )
                }
                if (viewModel.params.chroma != null) {
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .width(1.dp)
                            .height(22.dp)
                            .background(Color.White.copy(0.22f)),
                    )
                    ChromaParam.entries.forEach { item ->
                        TextChip(
                            title = viewModel.t(item.labelKey),
                            selected = chromaParam == item,
                            onClick = { chromaParam = item },
                        )
                    }
                }
            }
        }
        if (page == BgPage.SCENE && viewModel.params.backgroundFill == BackgroundFill.IMAGE) {
            BackgroundPresetGrid(viewModel)
        }
    }
}

@Composable
private fun BackgroundPresetGrid(viewModel: BeautySession) {
    val rows = BeautyCatalog.backgroundPresets.chunked(3)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        rows.forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { item ->
                    val selected = viewModel.params.bgPreset == item.id
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .border(
                                width = if (selected) 2.dp else 1.dp,
                                color = if (selected) Brand else Color.White.copy(0.12f),
                                shape = RoundedCornerShape(10.dp),
                            )
                            .clickable {
                                viewModel.updateParams {
                                    copy(bgPreset = item.id, backgroundFill = BackgroundFill.IMAGE)
                                }
                            }
                            .padding(3.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        PresetThumb(
                            id = item.id,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(52.dp),
                        )
                        Text(
                            viewModel.t(item.labelKey),
                            color = if (selected) Brand else Color.White.copy(0.85f),
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
                repeat(3 - row.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun PresetThumb(id: String, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val bitmap = remember(id) {
        runCatching {
            context.assets.open("facebetter/backgrounds/$id.jpg").use { BitmapFactory.decodeStream(it) }
        }.getOrNull()
    }
    if (bitmap != null) {
        Image(
            bitmap = bitmap.asImageBitmap(),
            contentDescription = null,
            modifier = modifier.clip(RoundedCornerShape(8.dp)),
            contentScale = ContentScale.Crop,
        )
    } else {
        Box(
            modifier = modifier
                .clip(RoundedCornerShape(8.dp))
                .background(Color.White.copy(0.08f)),
        )
    }
}

@Composable
private fun SecondaryTabBar(
    titles: List<String>,
    selected: Int,
    onSelect: (Int) -> Unit,
) {
    val scrolls = titles.size > 5
    if (scrolls) {
        val state = rememberLazyListState()
        LaunchedEffect(selected) {
            if (selected in titles.indices) {
                state.animateScrollToItem(selected)
            }
        }
        LazyRow(
            state = state,
            modifier = Modifier
                .fillMaxWidth()
                .height(38.dp),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            itemsIndexed(titles) { index, title ->
                SecondaryTab(
                    title = title,
                    selected = index == selected,
                    scrolls = true,
                    onClick = { onSelect(index) },
                )
            }
        }
    } else {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(38.dp)
                .padding(horizontal = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            titles.forEachIndexed { index, title ->
                SecondaryTab(
                    title = title,
                    selected = index == selected,
                    scrolls = false,
                    modifier = Modifier.weight(1f),
                    onClick = { onSelect(index) },
                )
            }
        }
    }
}

@Composable
private fun SecondaryTab(
    title: String,
    selected: Boolean,
    scrolls: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val tint = if (selected) Brand else Color.White.copy(0.5f)
    Column(
        modifier = modifier
            .height(38.dp)
            .then(if (scrolls) Modifier.padding(horizontal = 14.dp) else Modifier)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterVertically),
    ) {
        Text(
            title,
            color = tint,
            fontSize = 16.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
        Box(
            modifier = Modifier
                .width(19.dp)
                .height(2.dp)
                .background(if (selected) Brand else Color.Transparent, CircleShape),
        )
    }
}

@Composable
private fun ChipRow(content: @Composable RowScope.() -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

@Composable
private fun ColorRow(content: @Composable RowScope.() -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(40.dp)
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        content = content,
    )
}

@Composable
private fun TextChip(
    title: String,
    selected: Boolean,
    badge: String? = null,
    fillsWidth: Boolean = false,
    onClick: () -> Unit,
) {
    Box(
        modifier = if (fillsWidth) {
            Modifier
                .fillMaxWidth()
                .height(44.dp)
        } else {
            Modifier.size(width = 80.dp, height = 44.dp)
        },
    ) {
        Surface(
            onClick = onClick,
            modifier = Modifier.fillMaxSize(),
            shape = ChipShape,
            color = if (selected) Color.White else Color.White.copy(0.14f),
            contentColor = if (selected) Color.Black else Color.White,
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 6.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                )
            }
        }
        if (badge != null) {
            Text(
                badge,
                color = Color.Black,
                fontSize = 8.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(top = 5.dp, end = 5.dp)
                    .background(Color.Yellow, CircleShape)
                    .padding(horizontal = 4.dp, vertical = 1.dp),
            )
        }
    }
}

@Composable
private fun ColorDot(color: Color, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(29.dp)
                .background(color, CircleShape)
                .border(1.dp, Color.White.copy(0.35f), CircleShape),
        )
        if (selected) {
            Box(
                modifier = Modifier
                    .size(35.dp)
                    .border(3.dp, Brand, CircleShape),
            )
        }
    }
}

@Composable
private fun ColorChip(color: Color, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .background(color, CircleShape)
                .border(1.dp, Color.White.copy(0.35f), CircleShape),
        )
        if (selected) {
            Box(
                modifier = Modifier
                    .size(38.dp)
                    .border(2.dp, Color.White, CircleShape),
            )
        }
    }
}

@Composable
private fun CheckBox(title: String, checked: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier.clickable(
            interactionSource = remember { MutableInteractionSource() },
            indication = null,
            onClick = onClick,
        ),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .background(if (checked) Brand else Color.Transparent, RoundedCornerShape(4.dp))
                .border(
                    1.5.dp,
                    if (checked) Brand else Color.White.copy(0.55f),
                    RoundedCornerShape(4.dp),
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (checked) {
                Icon(
                    Icons.Outlined.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(12.dp),
                )
            }
        }
        Text(
            title,
            color = Color.White.copy(0.9f),
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
        )
    }
}

@Composable
private fun ResetButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(width = 28.dp, height = 32.dp)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick,
            ),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Outlined.Refresh,
            contentDescription = label,
            tint = Color.White.copy(0.9f),
            modifier = Modifier.size(15.dp),
        )
    }
}

@Composable
private fun SliderRow(
    title: String,
    value: Float,
    onValueChange: (Float) -> Unit,
    onReset: () -> Unit,
    resetLabel: String,
    signed: Boolean = false,
    enabled: Boolean = true,
    valueRange: ClosedFloatingPointRange<Float> = 0f..1f,
    trailing: @Composable (() -> Unit)? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(end = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ResetButton(
            label = resetLabel,
            onClick = onReset,
            modifier = Modifier.padding(start = 12.dp),
        )
        ValueSlider(
            title = title,
            value = value,
            onValueChange = onValueChange,
            signed = signed,
            enabled = enabled,
            valueRange = valueRange,
            modifier = Modifier.weight(1f),
        )
        if (trailing != null) {
            Spacer(modifier = Modifier.width(8.dp))
            trailing()
        }
    }
}

@Composable
private fun ValueSlider(
    title: String,
    value: Float,
    onValueChange: (Float) -> Unit,
    signed: Boolean,
    enabled: Boolean,
    valueRange: ClosedFloatingPointRange<Float>,
    modifier: Modifier = Modifier,
) {
    val readout = if (signed) {
        "%+.0f".format(value * 100f)
    } else {
        (value * 100f).roundToInt().toString()
    }
    Row(
        modifier = modifier.alpha(if (enabled) 1f else 0.38f),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            title,
            color = Color.White.copy(0.9f),
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.widthIn(max = 120.dp),
        )
        CenterSlider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            signed = signed,
            enabled = enabled,
            modifier = Modifier
                .weight(1f)
                .widthIn(min = 64.dp),
        )
        Text(
            readout,
            color = Color.White.copy(0.75f),
            fontSize = 12.sp,
            fontFamily = FontFamily.Monospace,
            textAlign = TextAlign.Start,
            maxLines = 1,
            modifier = Modifier.width(40.dp),
        )
    }
}

@Composable
private fun CenterSlider(
    value: Float,
    onValueChange: (Float) -> Unit,
    valueRange: ClosedFloatingPointRange<Float>,
    signed: Boolean,
    enabled: Boolean,
    modifier: Modifier = Modifier,
) {
    val onChange by rememberUpdatedState(onValueChange)
    Canvas(
        modifier
            .fillMaxWidth()
            .height(28.dp)
            .pointerInput(enabled, signed, valueRange) {
                if (!enabled) return@pointerInput
                val thumbPx = 28.dp.toPx()
                val span = (valueRange.endInclusive - valueRange.start).coerceAtLeast(0.0001f)
                awaitEachGesture {
                    val down = awaitFirstDown()
                    fun update(x: Float) {
                        val inset = thumbPx / 2f
                        val travel = (size.width - thumbPx).coerceAtLeast(1f)
                        val clamped = ((x - inset) / travel).coerceIn(0f, 1f)
                        onChange(valueRange.start + clamped * span)
                    }
                    update(down.position.x)
                    drag(down.id) { change ->
                        update(change.position.x)
                        change.consume()
                    }
                }
            },
    ) {
        val thumbW = 28.dp.toPx()
        val thumbH = 16.dp.toPx()
        val trackH = 4.dp.toPx()
        val inset = thumbW / 2f
        val travel = (size.width - thumbW).coerceAtLeast(1f)
        val span = (valueRange.endInclusive - valueRange.start).coerceAtLeast(0.0001f)
        val fraction = ((value - valueRange.start) / span).coerceIn(0f, 1f)
        val x = inset + fraction * travel
        val cy = size.height / 2f
        drawRoundRect(
            color = Color.White.copy(0.28f),
            topLeft = Offset(inset, cy - trackH / 2f),
            size = Size(travel, trackH),
            cornerRadius = CornerRadius(trackH / 2f),
        )
        val fillStart = if (signed) minOf(x, size.width / 2f) else inset
        val fillEnd = if (signed) maxOf(x, size.width / 2f) else x
        if (fillEnd - fillStart > 0.5f) {
            drawRoundRect(
                color = Color.White,
                topLeft = Offset(fillStart, cy - trackH / 2f),
                size = Size(fillEnd - fillStart, trackH),
                cornerRadius = CornerRadius(trackH / 2f),
            )
        }
        drawRoundRect(
            color = Color.Black.copy(0.18f),
            topLeft = Offset(x - inset, cy - thumbH / 2f + 0.5.dp.toPx()),
            size = Size(thumbW, thumbH),
            cornerRadius = CornerRadius(thumbH / 2f),
        )
        drawRoundRect(
            color = Color.White,
            topLeft = Offset(x - inset, cy - thumbH / 2f),
            size = Size(thumbW, thumbH),
            cornerRadius = CornerRadius(thumbH / 2f),
        )
    }
}

private fun makeupStyleSelected(viewModel: BeautySession, id: Any): Boolean {
    val params = viewModel.params
    return when (viewModel.selectedMakeup) {
        MakeupItem.BLUSH -> id == params.blushStyle
        MakeupItem.CONTOUR -> id == params.contourStyle
        MakeupItem.EYESHADOW -> id == params.eyeshadowStyle
        MakeupItem.EYELINER -> id == params.eyelinerStyle
        MakeupItem.EYEBROW -> id == params.eyebrowStyle
        MakeupItem.EYELASH -> id == params.eyelashStyle
        else -> false
    }
}

private fun applyMakeupStyle(viewModel: BeautySession, id: Any) {
    viewModel.updateParams {
        when (id) {
            is net.pixpark.facebetter.BeautyParams.BlushStyle -> copy(blushStyle = id)
            is net.pixpark.facebetter.BeautyParams.ContourStyle -> copy(contourStyle = id)
            is net.pixpark.facebetter.BeautyParams.EyeShadowStyle -> copy(eyeshadowStyle = id)
            is net.pixpark.facebetter.BeautyParams.EyeLinerStyle -> copy(eyelinerStyle = id)
            is net.pixpark.facebetter.BeautyParams.EyebrowStyle -> copy(eyebrowStyle = id)
            is net.pixpark.facebetter.BeautyParams.EyelashStyle -> copy(eyelashStyle = id)
            else -> this
        }
    }
}

private fun makeupColorSelected(viewModel: BeautySession, id: Any): Boolean {
    val params = viewModel.params
    return when (viewModel.selectedMakeup) {
        MakeupItem.LIPSTICK -> id == params.lipstickColor
        MakeupItem.BLUSH -> id == params.blushColor
        MakeupItem.EYESHADOW -> id == params.eyeshadowColor
        MakeupItem.EYELINER -> id == params.eyelinerColor
        MakeupItem.EYEBROW -> id == params.eyebrowColor
        MakeupItem.EYELASH -> id == params.eyelashColor
        MakeupItem.PUPIL -> id == params.pupilColor
        else -> false
    }
}

private fun applyMakeupColor(viewModel: BeautySession, id: Any) {
    viewModel.updateParams {
        when (id) {
            is net.pixpark.facebetter.BeautyParams.LipstickColor -> copy(lipstickColor = id)
            is net.pixpark.facebetter.BeautyParams.BlushColor -> copy(blushColor = id)
            is net.pixpark.facebetter.BeautyParams.EyeShadowColor -> copy(eyeshadowColor = id)
            is net.pixpark.facebetter.BeautyParams.EyeLinerColor -> copy(eyelinerColor = id)
            is net.pixpark.facebetter.BeautyParams.EyebrowColor -> copy(eyebrowColor = id)
            is net.pixpark.facebetter.BeautyParams.EyelashColor -> copy(eyelashColor = id)
            is net.pixpark.facebetter.BeautyParams.PupilColor -> copy(pupilColor = id)
            else -> this
        }
    }
}

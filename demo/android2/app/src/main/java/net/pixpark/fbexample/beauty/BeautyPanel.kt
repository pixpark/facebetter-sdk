package net.pixpark.fbexample.beauty

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Brush
import androidx.compose.material.icons.outlined.Face
import androidx.compose.material.icons.outlined.FilterVintage
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Wallpaper
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import net.pixpark.fbexample.studio.StudioViewModel
import net.pixpark.fbexample.studio.toPercent

@Composable
fun BeautyPanel(viewModel: StudioViewModel) {
    Column(
        modifier = Modifier
            .padding(horizontal = 8.dp, vertical = 6.dp)
            .background(Color.Black.copy(0.42f), RoundedCornerShape(24.dp))
            .padding(top = if (viewModel.panelExpanded) 10.dp else 8.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        AnimatedVisibility(
            visible = viewModel.panelExpanded,
            enter = expandVertically(),
            exit = shrinkVertically(),
        ) {
            when (viewModel.tab) {
                BeautyTab.SKIN -> SkinSection(viewModel)
                BeautyTab.RESHAPE -> ReshapeSection(viewModel)
                BeautyTab.MAKEUP -> MakeupSection(viewModel)
                BeautyTab.FILTER -> FilterSection(viewModel)
                BeautyTab.STICKER -> StickerSection(viewModel)
                BeautyTab.BACKGROUND -> BackgroundSection(viewModel)
            }
        }
        TabBar(viewModel)
    }
}

@Composable
private fun TabBar(viewModel: StudioViewModel) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        BeautyTab.entries.forEach { item ->
            val selected = viewModel.tab == item && viewModel.panelExpanded
            Surface(
                onClick = {
                    if (viewModel.tab == item && viewModel.panelExpanded) {
                        viewModel.panelExpanded = false
                    } else {
                        viewModel.tab = item
                        viewModel.panelExpanded = true
                    }
                },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                color = if (selected) Color.White else Color.Transparent,
                contentColor = if (selected) Color.Black else Color.White.copy(0.78f),
            ) {
                Column(
                    modifier = Modifier.padding(vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Icon(item.icon, contentDescription = viewModel.t(item.labelKey), modifier = Modifier.size(16.dp))
                    Text(viewModel.t(item.labelKey), fontSize = 10.sp, maxLines = 1)
                }
            }
        }
    }
}

private val BeautyTab.icon: ImageVector
    get() = when (this) {
        BeautyTab.SKIN -> Icons.Outlined.Face
        BeautyTab.RESHAPE -> Icons.Outlined.Person
        BeautyTab.MAKEUP -> Icons.Outlined.Brush
        BeautyTab.FILTER -> Icons.Outlined.FilterVintage
        BeautyTab.STICKER -> Icons.Outlined.AutoAwesome
        BeautyTab.BACKGROUND -> Icons.Outlined.Wallpaper
    }

@Composable
private fun SkinSection(viewModel: StudioViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        IntensitySlider(
            title = viewModel.t(viewModel.selectedSkin.labelKey),
            value = viewModel.params.skinIntensity(viewModel.selectedSkin),
            onChange = { value ->
                viewModel.updateParams { setSkinIntensity(viewModel.selectedSkin, value) }
            },
        )
        Row(
            modifier = Modifier.padding(horizontal = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ChipRow(modifier = Modifier.weight(1f), padded = false) {
                SkinItem.entries.forEach { item ->
                    ChoiceChip(
                        title = viewModel.t(item.labelKey),
                        selected = viewModel.selectedSkin == item,
                        onClick = { viewModel.selectedSkin = item },
                    )
                }
            }
            Text(
                text = viewModel.t("skin.skinOnly"),
                color = Color.White,
                fontSize = 12.sp,
                modifier = Modifier.padding(start = 8.dp, end = 8.dp),
            )
            Switch(
                checked = viewModel.params.skinOnly,
                onCheckedChange = { viewModel.updateParams { copy(skinOnly = it) } },
                colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = Color.White.copy(0.4f)),
            )
        }
        if (viewModel.selectedSkin == SkinItem.SMOOTHING) {
            ChipRow {
                BeautyCatalog.smoothingStyles.forEach { item ->
                    ChoiceChip(
                        title = viewModel.t(item.labelKey),
                        selected = viewModel.params.smoothingStyle == item.id,
                        onClick = { viewModel.updateParams { copy(smoothingStyle = item.id) } },
                    )
                }
            }
        }
        if (viewModel.selectedSkin == SkinItem.WHITENING) {
            ChipRow {
                BeautyCatalog.whiteningStyles.forEach { item ->
                    ChoiceChip(
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
private fun ReshapeSection(viewModel: StudioViewModel) {
    val value = viewModel.params.reshape[viewModel.selectedReshape] ?: 0f
    val title = BeautyCatalog.reshapeItems.firstOrNull { it.key == viewModel.selectedReshape }?.labelKey
        ?: "reshape.faceThin"
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        BipolarSlider(
            title = viewModel.t(title),
            value = value,
            onChange = { next ->
                viewModel.updateParams {
                    copy(reshape = reshape.toMutableMap().apply { put(viewModel.selectedReshape, next) })
                }
            },
        )
        ChipRow {
            BeautyCatalog.reshapeItems.forEach { item ->
                ChoiceChip(
                    title = viewModel.t(item.labelKey),
                    selected = viewModel.selectedReshape == item.key,
                    onClick = { viewModel.selectedReshape = item.key },
                )
            }
        }
    }
}

@Composable
private fun MakeupSection(viewModel: StudioViewModel) {
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
        MakeupItem.CONTOUR -> emptyList()
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ChipRow {
            MakeupItem.entries.forEach { item ->
                ChoiceChip(
                    title = viewModel.t(item.labelKey),
                    selected = viewModel.selectedMakeup == item,
                    onClick = { viewModel.selectedMakeup = item },
                )
            }
        }
        if (styles.isNotEmpty()) {
            Text(
                viewModel.t("makeup.style"),
                color = Color.White.copy(0.55f),
                fontSize = 11.sp,
                modifier = Modifier.padding(horizontal = 14.dp),
            )
            ChipRow {
                styles.forEach { item ->
                    ChoiceChip(
                        title = viewModel.t(item.labelKey),
                        selected = makeupStyleSelected(viewModel, item.id),
                        onClick = { applyMakeupStyle(viewModel, item.id) },
                    )
                }
            }
        }
        if (colors.isNotEmpty()) {
            Text(
                viewModel.t("makeup.color"),
                color = Color.White.copy(0.55f),
                fontSize = 11.sp,
                modifier = Modifier.padding(horizontal = 14.dp),
            )
            ChipRow {
                colors.forEach { item ->
                    ChoiceChip(
                        title = viewModel.t(item.labelKey),
                        selected = makeupColorSelected(viewModel, item.id),
                        color = item.color,
                        onClick = { applyMakeupColor(viewModel, item.id) },
                    )
                }
            }
        }
        IntensitySlider(
            title = viewModel.t("makeup.intensity"),
            value = viewModel.params.intensity(viewModel.selectedMakeup),
            onChange = { viewModel.updateParams { setIntensity(viewModel.selectedMakeup, it) } },
        )
    }
}

private fun makeupStyleSelected(viewModel: StudioViewModel, id: Any): Boolean {
    val params = viewModel.params
    return when (id) {
        params.blushStyle, params.contourStyle, params.eyeshadowStyle,
        params.eyelinerStyle, params.eyebrowStyle, params.eyelashStyle,
        -> true
        else -> false
    }
}

private fun applyMakeupStyle(viewModel: StudioViewModel, id: Any) {
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

private fun makeupColorSelected(viewModel: StudioViewModel, id: Any): Boolean {
    val params = viewModel.params
    return id == params.lipstickColor || id == params.blushColor || id == params.eyeshadowColor ||
        id == params.eyelinerColor || id == params.eyebrowColor || id == params.eyelashColor ||
        id == params.pupilColor
}

private fun applyMakeupColor(viewModel: StudioViewModel, id: Any) {
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

@Composable
private fun FilterSection(viewModel: StudioViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ChipRow {
            ChoiceChip(
                title = viewModel.t("filter.none"),
                selected = viewModel.params.filterId == null,
                onClick = { viewModel.updateParams { copy(filterId = null) } },
            )
            BeautyCatalog.filterIds.forEach { id ->
                ChoiceChip(
                    title = viewModel.filterLabel(id),
                    selected = viewModel.params.filterId == id,
                    onClick = { viewModel.updateParams { copy(filterId = id) } },
                )
            }
        }
        IntensitySlider(
            title = viewModel.t("filter.intensity"),
            value = viewModel.params.filterIntensity,
            enabled = viewModel.params.filterId != null,
            onChange = { viewModel.updateParams { copy(filterIntensity = it) } },
        )
    }
}

@Composable
private fun StickerSection(viewModel: StudioViewModel) {
    ChipRow {
        ChoiceChip(
            title = viewModel.t("sticker.none"),
            selected = viewModel.params.stickerId == null,
            onClick = { viewModel.updateParams { copy(stickerId = null) } },
        )
        BeautyCatalog.stickerIds.forEach { id ->
            ChoiceChip(
                title = viewModel.t("sticker.$id"),
                selected = viewModel.params.stickerId == id,
                onClick = { viewModel.updateParams { copy(stickerId = id) } },
            )
        }
    }
}

@Composable
private fun BackgroundSection(viewModel: StudioViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ChipRow {
            BackgroundFill.entries.forEach { fill ->
                ChoiceChip(
                    title = viewModel.t(fill.labelKey),
                    selected = viewModel.params.backgroundFill == fill,
                    onClick = { viewModel.updateParams { copy(backgroundFill = fill) } },
                )
            }
        }
        if (viewModel.params.backgroundFill == BackgroundFill.BLUR) {
            IntensitySlider(
                title = viewModel.t("bg.blurAmount"),
                value = viewModel.params.bgBlur,
                onChange = { viewModel.updateParams { copy(bgBlur = it) } },
            )
        }
        Text(
            viewModel.t("bg.cutout"),
            color = Color.White.copy(0.55f),
            fontSize = 11.sp,
            modifier = Modifier.padding(horizontal = 14.dp),
        )
        ChipRow {
            ChoiceChip(
                title = viewModel.t("bg.portrait"),
                selected = viewModel.params.chroma == null,
                onClick = { viewModel.updateParams { copy(chroma = null) } },
            )
            BeautyCatalog.chromaOptions.forEach { option ->
                ChoiceChip(
                    title = viewModel.t(option.labelKey),
                    selected = viewModel.params.chroma == option.id,
                    color = option.color,
                    onClick = { viewModel.updateParams { copy(chroma = option.id) } },
                )
            }
        }
        if (viewModel.params.chroma != null) {
            IntensitySlider(
                title = viewModel.t("bg.similarity"),
                value = viewModel.params.chromaSimilarity,
                onChange = { viewModel.updateParams { copy(chromaSimilarity = it) } },
            )
            IntensitySlider(
                title = viewModel.t("bg.smoothness"),
                value = viewModel.params.chromaSmoothness,
                onChange = { viewModel.updateParams { copy(chromaSmoothness = it) } },
            )
            IntensitySlider(
                title = viewModel.t("bg.desaturation"),
                value = viewModel.params.chromaDesaturation,
                onChange = { viewModel.updateParams { copy(chromaDesaturation = it) } },
            )
        }
    }
}

@Composable
private fun ChipRow(
    modifier: Modifier = Modifier,
    padded: Boolean = true,
    content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit,
) {
    Row(
        modifier = modifier
            .then(if (padded) Modifier.padding(horizontal = 14.dp) else Modifier)
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        content = content,
    )
}

@Composable
private fun ChoiceChip(
    title: String,
    selected: Boolean,
    color: Color? = null,
    onClick: () -> Unit,
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(50),
        color = if (selected) Color.White else Color.White.copy(0.12f),
        contentColor = if (selected) Color.Black else Color.White,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            if (color != null) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .background(color, CircleShape),
                )
            }
            Text(title, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
        }
    }
}

@Composable
private fun IntensitySlider(
    title: String,
    value: Float,
    enabled: Boolean = true,
    onChange: (Float) -> Unit,
) {
    Row(
        modifier = Modifier
            .padding(horizontal = 14.dp)
            .fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(title, color = Color.White.copy(0.85f), fontSize = 12.sp, modifier = Modifier.width(72.dp), maxLines = 1)
        Slider(
            value = value,
            onValueChange = onChange,
            enabled = enabled,
            valueRange = 0f..1f,
            modifier = Modifier.weight(1f),
            colors = SliderDefaults.colors(
                thumbColor = Color.White,
                activeTrackColor = Color.White,
                inactiveTrackColor = Color.White.copy(0.25f),
            ),
        )
        Text("${value.toPercent()}", color = Color.White.copy(0.8f), fontSize = 12.sp)
    }
}

@Composable
private fun BipolarSlider(
    title: String,
    value: Float,
    onChange: (Float) -> Unit,
) {
    Column(
        modifier = Modifier.padding(horizontal = 14.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, color = Color.White.copy(0.85f), fontSize = 12.sp)
            Text(
                text = "%+.0f".format(value * 100f),
                color = Color.White.copy(0.8f),
                fontSize = 12.sp,
            )
        }
        Slider(
            value = value,
            onValueChange = onChange,
            valueRange = -1f..1f,
            colors = SliderDefaults.colors(
                thumbColor = Color.White,
                activeTrackColor = Color.White,
                inactiveTrackColor = Color.White.copy(0.25f),
            ),
        )
    }
}

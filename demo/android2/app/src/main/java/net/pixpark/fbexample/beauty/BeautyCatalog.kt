package net.pixpark.fbexample.beauty

import androidx.compose.ui.graphics.Color
import net.pixpark.facebetter.BeautyParams.BlushColor
import net.pixpark.facebetter.BeautyParams.BlushStyle
import net.pixpark.facebetter.BeautyParams.ChromaKeyColor
import net.pixpark.facebetter.BeautyParams.ContourStyle
import net.pixpark.facebetter.BeautyParams.EyeLinerColor
import net.pixpark.facebetter.BeautyParams.EyeLinerStyle
import net.pixpark.facebetter.BeautyParams.EyeShadowColor
import net.pixpark.facebetter.BeautyParams.EyeShadowStyle
import net.pixpark.facebetter.BeautyParams.EyebrowColor
import net.pixpark.facebetter.BeautyParams.EyebrowStyle
import net.pixpark.facebetter.BeautyParams.EyelashColor
import net.pixpark.facebetter.BeautyParams.EyelashStyle
import net.pixpark.facebetter.BeautyParams.LipstickColor
import net.pixpark.facebetter.BeautyParams.PupilColor
import net.pixpark.facebetter.BeautyParams.Reshape
import net.pixpark.facebetter.BeautyParams.SmoothingStyle
import net.pixpark.facebetter.BeautyParams.WhiteningStyle

enum class BeautyTab(val labelKey: String) {
    SKIN("tab.skin"),
    RESHAPE("tab.reshape"),
    MAKEUP("tab.makeup"),
    FILTER("tab.filter"),
    STICKER("tab.sticker"),
    BACKGROUND("tab.background"),
}

enum class SkinItem(val labelKey: String) {
    SMOOTHING("skin.smoothing"),
    WHITENING("skin.whitening"),
    ROSINESS("skin.rosiness"),
    SHARPENING("skin.sharpening"),
}

enum class MakeupItem(val labelKey: String) {
    LIPSTICK("makeup.lipstick"),
    BLUSH("makeup.blush"),
    CONTOUR("makeup.contour"),
    EYESHADOW("makeup.eyeshadow"),
    EYELINER("makeup.eyeliner"),
    EYEBROW("makeup.eyebrow"),
    EYELASH("makeup.eyelash"),
    PUPIL("makeup.pupil"),
}

enum class BackgroundFill(val labelKey: String) {
    OFF("bg.original"),
    BLUR("bg.blur"),
    IMAGE("bg.preset"),
}

data class CatalogOption<T>(
    val id: T,
    val labelKey: String,
    val color: Color? = null,
)

data class ReshapeItem(
    val key: Reshape,
    val labelKey: String,
)

object BeautyCatalog {
    val smoothingStyles = listOf(
        CatalogOption(SmoothingStyle.NATURAL, "smoothing.natural"),
        CatalogOption(SmoothingStyle.TEXTURE, "smoothing.texture"),
        CatalogOption(SmoothingStyle.SMOOTH, "smoothing.smooth"),
    )

    val whiteningStyles = listOf(
        CatalogOption(WhiteningStyle.COLD_WHITE, "whitening.coldWhite"),
        CatalogOption(WhiteningStyle.PINK_WHITE, "whitening.pinkWhite"),
        CatalogOption(WhiteningStyle.WARM_WHITE, "whitening.warmWhite"),
        CatalogOption(WhiteningStyle.WHEAT, "whitening.wheat"),
        CatalogOption(WhiteningStyle.TAN, "whitening.tan"),
    )

    val reshapeItems = listOf(
        ReshapeItem(Reshape.FACE_THIN, "reshape.faceThin"),
        ReshapeItem(Reshape.FACE_NARROW, "reshape.faceNarrow"),
        ReshapeItem(Reshape.FACE_SMALL, "reshape.faceSmall"),
        ReshapeItem(Reshape.FACE_SHORT, "reshape.faceShort"),
        ReshapeItem(Reshape.FACE_V_SHAPE, "reshape.faceVShape"),
        ReshapeItem(Reshape.CHEEKBONE, "reshape.cheekbone"),
        ReshapeItem(Reshape.JAWBONE, "reshape.jawbone"),
        ReshapeItem(Reshape.CHIN, "reshape.chin"),
        ReshapeItem(Reshape.FOREHEAD, "reshape.forehead"),
        ReshapeItem(Reshape.BROW_POSITION, "reshape.browPosition"),
        ReshapeItem(Reshape.BROW_DISTANCE, "reshape.browDistance"),
        ReshapeItem(Reshape.BROW_THICKNESS, "reshape.browThickness"),
        ReshapeItem(Reshape.EYE_SIZE, "reshape.eyeSize"),
        ReshapeItem(Reshape.EYE_ROUND, "reshape.eyeRound"),
        ReshapeItem(Reshape.EYE_DISTANCE, "reshape.eyeDistance"),
        ReshapeItem(Reshape.EYE_POSITION, "reshape.eyePosition"),
        ReshapeItem(Reshape.EYE_ANGLE, "reshape.eyeAngle"),
        ReshapeItem(Reshape.EYE_CORNER_OPEN, "reshape.eyeCornerOpen"),
        ReshapeItem(Reshape.LOWER_EYELID, "reshape.lowerEyelid"),
        ReshapeItem(Reshape.NOSE_SLIM, "reshape.noseSlim"),
        ReshapeItem(Reshape.NOSE_LONG, "reshape.noseLong"),
        ReshapeItem(Reshape.PHILTRUM, "reshape.philtrum"),
        ReshapeItem(Reshape.MOUTH_SIZE, "reshape.mouthSize"),
        ReshapeItem(Reshape.MOUTH_POSITION, "reshape.mouthPosition"),
        ReshapeItem(Reshape.MOUTH_SMILE, "reshape.mouthSmile"),
        ReshapeItem(Reshape.LIP_THICKNESS, "reshape.lipThickness"),
    )

    val lipstickColors = listOf(
        CatalogOption(LipstickColor.ROUGE, "lipstick.rouge", Color(0xFFBE185D)),
        CatalogOption(LipstickColor.RETRO_RED, "lipstick.retroRed", Color(0xFFC2183B)),
        CatalogOption(LipstickColor.PEACH, "lipstick.peach", Color(0xFFFB7185)),
        CatalogOption(LipstickColor.CORAL_ORANGE, "lipstick.coralOrange", Color(0xFFD65129)),
        CatalogOption(LipstickColor.GENTLE_PINK, "lipstick.gentlePink", Color(0xFFF9A8D4)),
        CatalogOption(LipstickColor.VITALITY_ORANGE, "lipstick.vitalityOrange", Color(0xFFFB923C)),
    )

    val blushStyles = listOf(
        CatalogOption(BlushStyle.SUN_KISSED, "blush.sunKissed"),
        CatalogOption(BlushStyle.IGARI, "blush.igari"),
        CatalogOption(BlushStyle.SOFT, "blush.soft"),
        CatalogOption(BlushStyle.APPLE, "blush.apple"),
        CatalogOption(BlushStyle.CLASSIC, "blush.classic"),
        CatalogOption(BlushStyle.DOLL, "blush.doll"),
        CatalogOption(BlushStyle.ROSE, "blush.rose"),
    )

    val blushColors = listOf(
        CatalogOption(BlushColor.CORAL_PINK, "blushColor.coralPink", Color(0xFFB45309)),
        CatalogOption(BlushColor.DUSTY_ROSE, "blushColor.dustyRose", Color(0xFF9F1239)),
        CatalogOption(BlushColor.VIVID_RED, "blushColor.vividRed", Color(0xFFBE123C)),
        CatalogOption(BlushColor.BERRY, "blushColor.berry", Color(0xFF831843)),
        CatalogOption(BlushColor.SUNSET_ORANGE, "blushColor.sunsetOrange", Color(0xFFC2410C)),
    )

    val contourStyles = listOf(
        CatalogOption(ContourStyle.NATURAL, "contour.natural"),
        CatalogOption(ContourStyle.SCULPT, "contour.sculpt"),
        CatalogOption(ContourStyle.GLOW, "contour.glow"),
        CatalogOption(ContourStyle.SLIM, "contour.slim"),
        CatalogOption(ContourStyle.NOSE, "contour.nose"),
        CatalogOption(ContourStyle.GLAM, "contour.glam"),
    )

    val eyeshadowStyles = listOf(
        CatalogOption(EyeShadowStyle.SOFT, "eyeshadow.soft"),
        CatalogOption(EyeShadowStyle.CREASE, "eyeshadow.crease"),
        CatalogOption(EyeShadowStyle.SMOKY, "eyeshadow.smoky"),
        CatalogOption(EyeShadowStyle.HALO, "eyeshadow.halo"),
        CatalogOption(EyeShadowStyle.GLOW, "eyeshadow.glow"),
        CatalogOption(EyeShadowStyle.DRAMA, "eyeshadow.drama"),
        CatalogOption(EyeShadowStyle.WARM, "eyeshadow.warm"),
    )

    val eyeshadowColors = listOf(
        CatalogOption(EyeShadowColor.PLUM, "eyeshadowColor.plum", Color(0xFF6B21A8)),
        CatalogOption(EyeShadowColor.BROWN, "eyeshadowColor.brown", Color(0xFF78350F)),
        CatalogOption(EyeShadowColor.GOLD, "eyeshadowColor.gold", Color(0xFFA16207)),
        CatalogOption(EyeShadowColor.PINK, "eyeshadowColor.pink", Color(0xFF9D174D)),
    )

    val eyelinerStyles = listOf(
        CatalogOption(EyeLinerStyle.CLASSIC, "eyeliner.classic"),
        CatalogOption(EyeLinerStyle.FLICK, "eyeliner.flick"),
        CatalogOption(EyeLinerStyle.CAT_EYE, "eyeliner.catEye"),
        CatalogOption(EyeLinerStyle.NATURAL, "eyeliner.natural"),
        CatalogOption(EyeLinerStyle.BOLD, "eyeliner.bold"),
        CatalogOption(EyeLinerStyle.SOFT, "eyeliner.soft"),
    )

    val eyelinerColors = listOf(
        CatalogOption(EyeLinerColor.BURGUNDY, "eyelinerColor.burgundy", Color(0xFF7F1D1D)),
        CatalogOption(EyeLinerColor.PLUM, "eyelinerColor.plum", Color(0xFF581C87)),
        CatalogOption(EyeLinerColor.CHOCOLATE, "eyelinerColor.chocolate", Color(0xFF431407)),
        CatalogOption(EyeLinerColor.COFFEE, "eyelinerColor.coffee", Color(0xFF1C1917)),
        CatalogOption(EyeLinerColor.MAUVE, "eyelinerColor.mauve", Color(0xFF3F3F46)),
    )

    val eyebrowStyles = listOf(
        CatalogOption(EyebrowStyle.NATURAL, "eyebrow.natural"),
        CatalogOption(EyebrowStyle.SOFT, "eyebrow.soft"),
        CatalogOption(EyebrowStyle.FEATHERED, "eyebrow.feathered"),
        CatalogOption(EyebrowStyle.MIST, "eyebrow.mist"),
        CatalogOption(EyebrowStyle.ARCHED, "eyebrow.arched"),
        CatalogOption(EyebrowStyle.POWDER, "eyebrow.powder"),
        CatalogOption(EyebrowStyle.WILD, "eyebrow.wild"),
        CatalogOption(EyebrowStyle.FULL, "eyebrow.full"),
        CatalogOption(EyebrowStyle.STRAIGHT, "eyebrow.straight"),
    )

    val eyebrowColors = listOf(
        CatalogOption(EyebrowColor.DARK_BROWN, "eyebrowColor.darkBrown", Color(0xFF44403C)),
        CatalogOption(EyebrowColor.BLACK, "eyebrowColor.black", Color(0xFF18181B)),
        CatalogOption(EyebrowColor.SOFT_BROWN, "eyebrowColor.softBrown", Color(0xFF78716C)),
    )

    val eyelashStyles = listOf(
        CatalogOption(EyelashStyle.CLASSIC, "eyelash.classic"),
        CatalogOption(EyelashStyle.MANGA, "eyelash.manga"),
        CatalogOption(EyelashStyle.WINGED, "eyelash.winged"),
        CatalogOption(EyelashStyle.WISPY, "eyelash.wispy"),
        CatalogOption(EyelashStyle.CLUSTERED, "eyelash.clustered"),
        CatalogOption(EyelashStyle.DOLL, "eyelash.doll"),
    )

    val eyelashColors = listOf(
        CatalogOption(EyelashColor.BLACK, "eyelashColor.black", Color(0xFF09090B)),
        CatalogOption(EyelashColor.BROWN, "eyelashColor.brown", Color(0xFF44403C)),
        CatalogOption(EyelashColor.SOFT_BLACK, "eyelashColor.softBlack", Color(0xFF27272A)),
    )

    val pupilColors = listOf(
        CatalogOption(PupilColor.HAZEL, "pupil.hazel", Color(0xFF92400E)),
        CatalogOption(PupilColor.ICE, "pupil.ice", Color(0xFF7DD3FC)),
        CatalogOption(PupilColor.MOCHA, "pupil.mocha", Color(0xFF44403C)),
        CatalogOption(PupilColor.OLIVE, "pupil.olive", Color(0xFF3F6212)),
        CatalogOption(PupilColor.GLOSS, "pupil.gloss", Color(0xFF292524)),
        CatalogOption(PupilColor.MOSS, "pupil.moss", Color(0xFF4D7C0F)),
        CatalogOption(PupilColor.SAND, "pupil.sand", Color(0xFFA8A29E)),
        CatalogOption(PupilColor.GLOW, "pupil.glow", Color(0xFFFDE68A)),
        CatalogOption(PupilColor.SLATE, "pupil.slate", Color(0xFF64748B)),
    )

    val chromaOptions = listOf(
        CatalogOption(ChromaKeyColor.GREEN, "bg.green", Color(0xFF22C55E)),
        CatalogOption(ChromaKeyColor.BLUE, "bg.blue", Color(0xFF3B82F6)),
        CatalogOption(ChromaKeyColor.RED, "bg.red", Color(0xFFEF4444)),
    )

    val filterIds = listOf(
        "initial_heart", "first_love", "vivid", "confession", "milk_tea", "mousse",
        "japanese", "dawn", "cookie", "lively", "pure", "fair", "snow", "plain",
        "natural", "rose", "tender", "tender_2", "extraordinary",
    )

    val stickerIds = listOf(
        "black_glass", "pixel_glass", "fox", "antler", "crown", "hat", "hat3",
        "kiss", "kiss2", "mustache", "mustache2",
    )
}

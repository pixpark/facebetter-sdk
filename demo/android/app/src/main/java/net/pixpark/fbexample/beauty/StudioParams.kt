package net.pixpark.fbexample.beauty

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

data class StudioParams(
    val smoothing: Float = 0f,
    val smoothingStyle: SmoothingStyle = SmoothingStyle.TEXTURE,
    val whitening: Float = 0f,
    val whiteningStyle: WhiteningStyle = WhiteningStyle.COLD_WHITE,
    val rosiness: Float = 0f,
    val sharpening: Float = 0f,
    val skinOnly: Boolean = false,
    val reshape: Map<Reshape, Float> = BeautyCatalog.reshapeItems.associate { it.key to 0f },
    val lipstick: Float = 0f,
    val lipstickColor: LipstickColor = LipstickColor.ROUGE,
    val blush: Float = 0f,
    val blushStyle: BlushStyle = BlushStyle.SOFT,
    val blushColor: BlushColor = BlushColor.CORAL_PINK,
    val contour: Float = 0f,
    val contourStyle: ContourStyle = ContourStyle.NATURAL,
    val eyeshadow: Float = 0f,
    val eyeshadowStyle: EyeShadowStyle = EyeShadowStyle.SOFT,
    val eyeshadowColor: EyeShadowColor = EyeShadowColor.PLUM,
    val eyeliner: Float = 0f,
    val eyelinerStyle: EyeLinerStyle = EyeLinerStyle.CLASSIC,
    val eyelinerColor: EyeLinerColor = EyeLinerColor.COFFEE,
    val eyebrow: Float = 0f,
    val eyebrowStyle: EyebrowStyle = EyebrowStyle.NATURAL,
    val eyebrowColor: EyebrowColor = EyebrowColor.DARK_BROWN,
    val eyelash: Float = 0f,
    val eyelashStyle: EyelashStyle = EyelashStyle.CLASSIC,
    val eyelashColor: EyelashColor = EyelashColor.BLACK,
    val pupil: Float = 0f,
    val pupilColor: PupilColor = PupilColor.HAZEL,
    val filterId: String? = null,
    val filterIntensity: Float = 0.8f,
    val stickerId: String? = null,
    val backgroundFill: BackgroundFill = BackgroundFill.OFF,
    val bgBlur: Float = 0.5f,
    val chroma: ChromaKeyColor? = null,
    val chromaSimilarity: Float = 0.4f,
    val chromaSmoothness: Float = 0.1f,
    val chromaDesaturation: Float = 0.1f,
) {
    fun intensity(item: MakeupItem): Float = when (item) {
        MakeupItem.LIPSTICK -> lipstick
        MakeupItem.BLUSH -> blush
        MakeupItem.CONTOUR -> contour
        MakeupItem.EYESHADOW -> eyeshadow
        MakeupItem.EYELINER -> eyeliner
        MakeupItem.EYEBROW -> eyebrow
        MakeupItem.EYELASH -> eyelash
        MakeupItem.PUPIL -> pupil
    }

    fun setIntensity(item: MakeupItem, value: Float): StudioParams = when (item) {
        MakeupItem.LIPSTICK -> copy(lipstick = value)
        MakeupItem.BLUSH -> copy(blush = value)
        MakeupItem.CONTOUR -> copy(contour = value)
        MakeupItem.EYESHADOW -> copy(eyeshadow = value)
        MakeupItem.EYELINER -> copy(eyeliner = value)
        MakeupItem.EYEBROW -> copy(eyebrow = value)
        MakeupItem.EYELASH -> copy(eyelash = value)
        MakeupItem.PUPIL -> copy(pupil = value)
    }

    fun skinIntensity(item: SkinItem): Float = when (item) {
        SkinItem.SMOOTHING -> smoothing
        SkinItem.WHITENING -> whitening
        SkinItem.ROSINESS -> rosiness
        SkinItem.SHARPENING -> sharpening
    }

    fun setSkinIntensity(item: SkinItem, value: Float): StudioParams = when (item) {
        SkinItem.SMOOTHING -> copy(smoothing = value)
        SkinItem.WHITENING -> copy(whitening = value)
        SkinItem.ROSINESS -> copy(rosiness = value)
        SkinItem.SHARPENING -> copy(sharpening = value)
    }
}

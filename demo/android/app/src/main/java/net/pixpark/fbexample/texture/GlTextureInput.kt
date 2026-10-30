package net.pixpark.fbexample.texture

import net.pixpark.fbexample.engine.BeautyEngine

/** External-texture call. Invoke it on the thread that owns the GL context. */
object GlTextureInput {
    fun process(
        texture: Int,
        width: Int,
        height: Int,
        engine: BeautyEngine,
        bypass: Boolean,
    ): Int = engine.processTexture(texture, width, height, bypass)
}

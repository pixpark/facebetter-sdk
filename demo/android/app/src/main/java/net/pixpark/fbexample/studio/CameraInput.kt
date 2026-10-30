package net.pixpark.fbexample.studio

/** How a camera frame is handed to the engine. Gallery stills always use the image API. */
enum class CameraInput {
    CPU,
    GL_TEXTURE,
    ;

    val shortKey: String
        get() = when (this) {
            CPU -> "input.cpu.short"
            GL_TEXTURE -> "input.gl.short"
        }
}

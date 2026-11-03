import { registerWebModule, NativeModule } from 'expo';

class FacebetterCameraModule extends NativeModule<{}> {}

export default registerWebModule(FacebetterCameraModule, 'FacebetterCameraModule');

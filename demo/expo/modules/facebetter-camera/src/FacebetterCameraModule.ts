import { NativeModule, requireNativeModule } from 'expo';

declare class FacebetterCameraModule extends NativeModule<{}> {}

export default requireNativeModule<FacebetterCameraModule>('FacebetterCamera');

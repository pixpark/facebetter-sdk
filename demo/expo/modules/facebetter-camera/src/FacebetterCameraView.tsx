import { requireNativeView } from "expo";
import type { StyleProp, ViewStyle } from "react-native";

export type FacebetterCameraProps = {
  smoothing?: number;
  whitening?: number;
  rosiness?: number;
  blemish?: number;
  clarity?: number;
  skinOnly?: boolean;
  onStatus?: (event: { nativeEvent: { status: string } }) => void;
  style?: StyleProp<ViewStyle>;
};

const NativeView = requireNativeView<FacebetterCameraProps>("FacebetterCamera");

export default function FacebetterCameraView(props: FacebetterCameraProps) {
  return <NativeView {...props} />;
}

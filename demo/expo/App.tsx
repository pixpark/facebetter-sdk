import Slider from "@react-native-community/slider";
import { useEffect, useState } from "react";
import {
  PermissionsAndroid,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";

import FacebetterCameraView from "./modules/facebetter-camera/src/FacebetterCameraView";

type SkinKey = "smoothing" | "whitening" | "rosiness" | "blemish" | "clarity";

const ROWS: { key: SkinKey; label: string }[] = [
  { key: "smoothing", label: "Smooth" },
  { key: "whitening", label: "Tone" },
  { key: "rosiness", label: "Rosy" },
  { key: "blemish", label: "Blemish" },
  { key: "clarity", label: "Clarity" },
];

export default function App() {
  const [granted, setGranted] = useState(false);
  const [status, setStatus] = useState("starting");
  const [skinOnly, setSkinOnly] = useState(false);
  const [skin, setSkin] = useState({
    smoothing: 0.6,
    whitening: 0.3,
    rosiness: 0.15,
    blemish: 0,
    clarity: 0.2,
  });

  useEffect(() => {
    PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA).then(
      (result) => {
        setGranted(result === PermissionsAndroid.RESULTS.GRANTED);
        if (result !== PermissionsAndroid.RESULTS.GRANTED) {
          setStatus("cameraDenied");
        }
      },
    );
  }, []);

  return (
    <View style={styles.root}>
      {granted ? (
        <FacebetterCameraView
          style={styles.preview}
          smoothing={skin.smoothing}
          whitening={skin.whitening}
          rosiness={skin.rosiness}
          blemish={skin.blemish}
          clarity={skin.clarity}
          skinOnly={skinOnly}
          onStatus={(event) => setStatus(event.nativeEvent.status)}
        />
      ) : (
        <View style={styles.preview}>
          <Text style={styles.denied}>Camera permission is required</Text>
        </View>
      )}
      <View style={styles.panel}>
        <Text style={styles.status}>{status}</Text>
        {ROWS.map((row) => (
          <View key={row.key} style={styles.row}>
            <Text style={styles.label}>
              {row.label} {skin[row.key].toFixed(2)}
            </Text>
            <Slider
              style={styles.slider}
              minimumValue={0}
              maximumValue={1}
              value={skin[row.key]}
              onValueChange={(value) =>
                setSkin((current) => ({ ...current, [row.key]: value }))
              }
            />
          </View>
        ))}
        <Pressable onPress={() => setSkinOnly((value) => !value)}>
          <Text style={styles.label}>Skin only {skinOnly ? "On" : "Off"}</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#000" },
  preview: { flex: 1, alignItems: "center", justifyContent: "center" },
  denied: { color: "#fff" },
  panel: {
    backgroundColor: "#111",
    paddingHorizontal: 8,
    paddingTop: 8,
    paddingBottom: 56,
  },
  status: { color: "#aaa", fontSize: 12 },
  row: { height: 36, justifyContent: "center" },
  label: { color: "#fff", fontSize: 13 },
  slider: { height: 24, marginHorizontal: 28 },
});

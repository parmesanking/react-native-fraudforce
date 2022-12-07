import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity, NativeEventEmitter, NativeModules } from 'react-native';
import Fraudforce from 'react-native-fraudforce';

//const { ModuleWithEmitter } = NativeModules;

const eventEmitter = new NativeEventEmitter(NativeModules.Fraudforce);

const subscription = eventEmitter.addListener('onPerimeterXRequestBlocked', (data) => {
  console.log("onPerimeterXRequestBlocked", data)
})


export const extractBody = (res) => {
  if (res.ok) {
    return res.json()
  } else {
    // global.ourLog('problem with result', res)
    return res.text().then((text) => {
      // global.ourLog('ERROR from Fetch ----> ', text, 'Link ', res.__internalLink, res)
      if (res.status === 504) {
        //server timed out, returning a generic error
        text = 'An error has occured.'
      }
      throw new Error(text)
    })
  }
}


export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  React.useEffect(() => {
    Fraudforce.blackbox().then(data => {
      setResult(data.length)
      console.log(data)
    });
  }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
      <TouchableOpacity onPress={async () => {
        await Fraudforce.startPerimeterX("PXMfr5fk9F").then(() => { console.log("YO") }).catch(() => { console.log("YAY") })
        Fraudforce.getPerimeterXHeaders(async (headers) => {
          const obj = JSON.parse(headers);
          console.log("-->", {
            ...obj, Accept: 'application/json',
            'Accept-Language': 'en-us',
            'Content-Type': 'application/json'
          })
          const url = 'https://c69e-79-9-210-182.ngrok.io/testPX'
          let statusCode
          await fetch(url, {
            method: 'POST',
            headers: {
              ...obj, Accept: 'application/json',
              'Accept-Language': 'en-us',
              'Content-Type': 'application/json'
            }
          }).then(res => {
            statusCode = res.status
            return res
          }).then(extractBody).then(data => {
            console.log(statusCode)
            console.log(data)
            Fraudforce.handleResponse(JSON.stringify(data), statusCode, url);
            console.log(data)

          }).catch(e => console.error(e.message))


        })
      }}><Text>PerimeterX</Text></TouchableOpacity>
    </View >
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});

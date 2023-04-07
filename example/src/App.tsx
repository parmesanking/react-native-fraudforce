import * as React from 'react';

import { StyleSheet, View, Text, TouchableOpacity, NativeEventEmitter, NativeModules } from 'react-native';
import Fraudforce from 'react-native-fraudforce';

//const { ModuleWithEmitter } = NativeModules;

const eventEmitter = new NativeEventEmitter(NativeModules.Fraudforce);

const subscription = eventEmitter.addListener('onPerimeterXRequestBlocked', (data) => {
  console.log("onPerimeterXRequestBlocked", data)
})


if (global.__fbBatchedBridge) {
  const origMessageQueue = global.__fbBatchedBridge;
  const modules = origMessageQueue._remoteModuleTable;
  const methods = origMessageQueue._remoteMethodTable;
  global.findModuleByModuleAndMethodIds = (moduleId, methodId) => {
    console.log(`The problematic line code is in: ${modules[moduleId]}.${methods[moduleId][methodId]}`)
  }
}

//global.findModuleByModuleAndMethodIds(65, 9);

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
        await Fraudforce.startPerimeterX("PXMfr5fk9F", ["api.betcha.one", "stage-api.betcha.one"]).then(() => {
          console.log("YO")
        }).catch((e) => {
          console.log("YAY", e.message)
        })

        await Fraudforce.getPerimeterXHeaders().then(async (headers) => {
          console.log("HEAD", headers)
          //const obj = JSON.parse(headers);
          obj = headers
          console.log("-->", {
            ...obj, Accept: 'application/json',
            'Accept-Language': 'en-us',
            'Content-Type': 'application/json',

          })
          const url = 'https://stage-api.betcha.one/v1/login'
          let statusCode
          await fetch(url, {
            method: 'POST',
            headers: {
              ...obj, Accept: 'application/json',
              'Accept-Language': 'en-us',
              'Content-Type': 'application/json', "betcha-device": "123345",
              decorateBraze: true,
              "betcha-version": "ios(16.3.1)/167/1cde43c7"
            }
          }).then(res => {
            statusCode = res.status

            return res
          }).then(extractBody).then(data => {
            console.log(statusCode)
            console.log(data)
            Fraudforce.handleResponse(JSON.stringify(data), statusCode, url);
            console.log(data)

          }).catch(e => { console.error(e.message) })


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

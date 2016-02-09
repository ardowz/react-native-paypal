'use strict';
var {NativeModules, Platform} = require('react-native')
var {PayPal, MFLReactNativePayPal} = NativeModules;

var constants;

if (Platform.OS === 'android') {
  constants = {};
  var constantNames = Object.keys(PayPal).filter(p => p == p.toUpperCase());
  constantNames.forEach(c => constants[c] = PayPal[c]);
} else {
  constants = {
    SANDBOX: 0,
    PRODUCTION: 1,
    NO_NETWORK: 2,

    USER_CANCELLED: 'USER_CANCELLED',
    INVALID_CONFIG: 'INVALID_CONFIG'
  }
}

var functions = {
  paymentRequest(payPalParameters) {
    return new Promise(function(resolve, reject) {
      if (Platform.OS === 'android') {
        PayPal.paymentRequest(payPalParameters, resolve, reject);
      } else {
        MFLReactNativePayPal.initializePaypalEnvironment(payPalParameters.environment, payPalParameters.clientId);
        MFLReactNativePayPal.preparePaymentOfAmount(payPalParameters.price, payPalParameters.currency, payPalParameters.description);
        MFLReactNativePayPal.prepareConfigurationForMerchant("Shape A Future", true, "spenden@aktion-europa-hilft.de");
        MFLReactNativePayPal.presentPaymentViewControllerForPreparedPurchase((error, payload) => {
          if (error) {
             reject(constants.INVALID_CONFIG, error)
           } else {
            if (payload.status === 1) {
              resolve(payload);
            } else {
              reject(constants.USER_CANCELLED, payload);
            }
           }
        });
      }
    });
  },
  futurePaymentRequest(payPalParameters) {
    return new Promise(function(resolve, reject) {
      if (Platform.OS === 'android') {
        PayPal.futurePaymentRequest(payPalParameters, resolve, reject);
      } else {
        MFLReactNativePayPal.initializePaypalEnvironment(payPalParameters.environment, payPalParameters.clientId);
        MFLReactNativePayPal.prepareConfigurationForMerchant(payPalParameters.merchantName, payPalParameters.privacyPolicyURL, payPalParameters.userAgreementURL);

        MFLReactNativePayPal.presentPaymentViewControllerForPreparedPurchase((payload, error) => {
            if (payload) {
              var payload = JSON.parse(payload);
              if (payload.response_type == 'authorization_code') {
                resolve(payload);
                //var authCode = payload.response.code;
                //console.log(authCode);
              } else {
                reject(constants.USER_CANCELLED, payload);
                //console.log("User cancelled payment");
              }
            } else {
              reject(constants.INVALID_CONFIG, error)
              //console.log(error);
              //return;
            }
        });

      }

    });
  }
};

var exported = {};
Object.assign(exported, constants, functions);

module.exports = exported;

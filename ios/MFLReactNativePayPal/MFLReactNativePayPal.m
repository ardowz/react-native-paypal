//
//  MFLReactNativePayPal.m
//  ReactPaypal
//
//  Created by Tj on 6/22/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MFLReactNativePayPal.h"
#import "RCTBridge.h"
#import "PayPalMobile.h"

NSString * const kPayPalPaymentStatusKey              = @"status";
NSString * const kPayPalPaymentConfirmationKey        = @"confirmation";

@interface MFLReactNativePayPal () <PayPalFuturePaymentDelegate, RCTBridgeModule>

@property PayPalConfiguration *configuration;
@property (copy) RCTResponseSenderBlock flowCompletedCallback;

@end

@implementation MFLReactNativePayPal

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initializePaypalEnvironment:(int)environment
                  forClientId:(NSString *)clientId )
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *envString = [self stringFromEnvironmentEnum:environment];
        
        [PayPalMobile initializeWithClientIdsForEnvironments:@{envString : clientId}];
        [PayPalMobile preconnectWithEnvironment:envString];
    });
}

#pragma mark React Exported Methods

RCT_EXPORT_METHOD(prepareConfigurationForMerchant:(NSString *)merchantName
                  merchantPrivacyPolicy:(NSString *)privacyPolicy
                  merchantUserAgreement:(NSString *)userAgreement)
{
    self.configuration = [[PayPalConfiguration alloc] init];
    [self.configuration setMerchantName:merchantName];
    [self.configuration setMerchantPrivacyPolicyURL:[NSURL URLWithString:privacyPolicy]];
    [self.configuration setMerchantUserAgreementURL:[NSURL URLWithString:userAgreement]];
}


RCT_EXPORT_METHOD(presentPaymentViewControllerForPreparedPurchase:(RCTResponseSenderBlock)flowCompletedCallback)
{
    self.flowCompletedCallback = flowCompletedCallback;
    
    //  PayPalPaymentViewController *vc = [[PayPalPaymentViewController alloc] initWithPayment:self.payment
    //                                                                           configuration:self.configuration
    //                                                                                delegate:self];
    PayPalFuturePaymentViewController *fpViewController;
    fpViewController = [[PayPalFuturePaymentViewController alloc] initWithConfiguration:self.configuration
                                                                               delegate:self];
    
    // Present the PayPalFuturePaymentViewController
    UIViewController *visibleVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    do {
        if ([visibleVC isKindOfClass:[UINavigationController class]]) {
            visibleVC = [(UINavigationController *)visibleVC visibleViewController];
        } else if (visibleVC.presentedViewController) {
            visibleVC = visibleVC.presentedViewController;
        }
    } while (visibleVC.presentedViewController);
    
    [visibleVC presentViewController:fpViewController animated:YES completion:nil];
    
    //  UIViewController *visibleVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    //  do {
    //    if ([visibleVC isKindOfClass:[UINavigationController class]]) {
    //      visibleVC = [(UINavigationController *)visibleVC visibleViewController];
    //    } else if (visibleVC.presentedViewController) {
    //      visibleVC = visibleVC.presentedViewController;
    //    }
    //  } while (visibleVC.presentedViewController);
    //
    //  [visibleVC presentViewController:vc animated:YES completion:nil];
}

#pragma mark - PayPalFuturePaymentDelegate methods

- (void)payPalFuturePaymentDidCancel:(PayPalFuturePaymentViewController *)futurePaymentViewController {
    // User cancelled login. Dismiss the PayPalLoginViewController, breathe deeply.
    //    [self dismissViewControllerAnimated:YES completion:nil];
    [futurePaymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.flowCompletedCallback) {
            self.flowCompletedCallback(@[[NSNull null], @{kPayPalPaymentStatusKey : @(kPayPalPaymentCanceled)}]);
        }
    }];
    
}

- (void)payPalFuturePaymentViewController:(PayPalFuturePaymentViewController *)futurePaymentViewController
                didAuthorizeFuturePayment:(NSDictionary *)futurePaymentAuthorization {
    // The user has successfully logged into PayPal, and has consented to future payments.
    
    // Your code must now send the authorization response to your server.
    
    [futurePaymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.flowCompletedCallback) {
            [self sendAuthorizationToServer:futurePaymentAuthorization];
        }
    }];
    
    
    // Be sure to dismiss the PayPalLoginViewController.
    //    [self dismissViewControllerAnimated:YES completion:nil];
    [futurePaymentViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.flowCompletedCallback) {
            self.flowCompletedCallback(@[[NSNull null], @{kPayPalPaymentStatusKey : @(kPayPalPaymentCanceled)}]);
        }
    }];
}

- (void)sendAuthorizationToServer:(NSDictionary *)authorization {
    // Send the entire authorization reponse
    NSData *consentJSONData = [NSJSONSerialization dataWithJSONObject:authorization
                                                              options:0
                                                                error:nil];
    
    NSString * myString = [[NSString alloc] initWithData:consentJSONData encoding:NSUTF8StringEncoding];
    
    if (self.flowCompletedCallback) {
        self.flowCompletedCallback(@[myString, @{kPayPalPaymentStatusKey : @(kPayPalPaymentCanceled)}]);
    }
    // (Your network code here!)
    //
    // Send the authorization response to your server, where it can exchange the authorization code
    // for OAuth access and refresh tokens.
    //
    // Your server must then store these tokens, so that your server code can execute payments
    // for this user in the future.
}

#pragma mark Utilities

- (NSString *)stringFromEnvironmentEnum:(PayPalEnvironment)env
{
    switch (env) {
        case kPayPalEnvironmentProduction: return PayPalEnvironmentProduction;
        case kPayPalEnvironmentSandbox: return PayPalEnvironmentSandbox;
        case kPayPalEnvironmentSandboxNoNetwork: return PayPalEnvironmentNoNetwork;
    }
}

@end

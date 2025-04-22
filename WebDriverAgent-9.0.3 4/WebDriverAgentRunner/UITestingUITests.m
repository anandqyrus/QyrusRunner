/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <WebDriverAgentLib/FBDebugLogDelegateDecorator.h>
#import <WebDriverAgentLib/FBConfiguration.h>
#import <WebDriverAgentLib/FBFailureProofTestCase.h>
#import <WebDriverAgentLib/FBWebServer.h>
#import <WebDriverAgentLib/XCTestCase.h>

@interface UITestingUITests : FBFailureProofTestCase <FBWebServerDelegate>
@end

@implementation UITestingUITests

-(void)setUp
{
  [FBDebugLogDelegateDecorator decorateXCTestLogger];
  [FBConfiguration disableRemoteQueryEvaluation];
  [FBConfiguration configureDefaultKeyboardPreferences];
  [FBConfiguration disableApplicationUIInterruptionsHandling];
  if (NSProcessInfo.processInfo.environment[@"ENABLE_AUTOMATIC_SCREEN_RECORDINGS"]) {
    [FBConfiguration enableScreenRecordings];
  } else {
    [FBConfiguration disableScreenRecordings];
  }
  if (NSProcessInfo.processInfo.environment[@"ENABLE_AUTOMATIC_SCREENSHOTS"]) {
    [FBConfiguration enableScreenshots];
  } else {
    [FBConfiguration disableScreenshots];
  }
 
  [self handleAlertIfExists];
  
  [super setUp];
  
}
//Pragma Mark - disable the system alerts
- (void)handleAlertIfExists {
    XCUIApplication *springboard = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
    XCUIElement *alert = springboard.alerts.element;
  
    if (alert.exists) {
        NSArray *buttons = @[@"Allow", @"Don't Allow", @"Settings", @"Not Now", @"OK", @"Cancel", @"Remind Me Later", @"Try Again", @"Continue", @"Allow Once",@"Microphone",@"Close",@"X",@"Headphones"];
        
        for (NSString *button in buttons) {
            XCUIElement *alertButton = [alert.buttons elementMatchingPredicate:[NSPredicate predicateWithFormat:@"label == %@", button]];
            if (alertButton.exists) {
                [alertButton tap];
                XCTAssertTrue(YES, @"%@ button tapped", button);
                return;
            }
        }
       // XCTFail()
        // If no known buttons were found
       // XCTFail(@"Unhandled alert button: %@", alert.buttons.element.label);
    }
}
-(void)handleAppstoreAlert
{
  XCUIApplication *springboard = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  XCUIElement *window = [[springboard.windows elementBoundByIndex:0] firstMatch];

  XCUICoordinate *closeButtonArea = [window coordinateWithNormalizedOffset:CGVectorMake(0.95, 0.05)];
  [closeButtonArea tap];
}


- (void)recordFailureWithDescription:(NSString *)description
                              inFile:(NSString *)filePath
                              atLine:(NSUInteger)lineNumber
                            expected:(BOOL)expected
{
    if ([description containsString:@"Allow Camera to Use Your Location"]) {
        NSLog(@"Location permission alert detected, ignoring failure...");
        return;  // Prevents failure caused by the system alert
    } [self addUIInterruptionMonitorWithDescription:@"System Alert" handler:^BOOL(XCUIElement * _Nonnull alert) {
      if ([alert.label containsString:@"Allow Camera to Use Your Location"]) {
          XCUIElement *allowButton = alert.buttons[@"Allow Once"];
          if (allowButton.exists) {
              [allowButton tap];  // Automatically tap "Allow"
              return YES;
          }
      }
      return NO;
  }];
    [super recordFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
}

-(void)dismissalertssss {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  while (app.alerts.count > 0) {
    XCUIElement *alert = app.alerts.firstMatch;
    if(alert.buttons.count > 0){
      [alert.buttons.element.firstMatch tap];
    }
  }
  
}
//-(void)tearDown {
//  [self dismissAlerts];
//  [super tearDown];
//}

-(void)dismissAlerts{
  XCUIApplication *app = [[XCUIApplication alloc] init];
    NSArray *alerts = app.alerts.allElementsBoundByIndex;
  for (XCUIElement *alert in alerts)
  {
    if(alert.buttons.count > 0){
      //check for a specific button or Action
      if([alert.buttons[@"Allow Once"] exists])
      {
        [alert.buttons[@"Allow Once"] tap];
        
      }else if ([alert.buttons[@"Ok"] exists])
      {
        [alert.buttons[@"OK"] tap];
      }
      else if ([alert.buttons[@"Allow"] exists])
      {
        [alert.buttons[@"Allow"] tap];
      }
      else if ([alert.buttons[@"Cancel"] exists]){
        [alert.buttons[@"Cancel"] tap];
        
      }
      else{
        [alert.buttons.element.firstMatch tap];
      }
    }
  }
 

}
/**
 Never ending test used to start WebDriverAgent
 */
- (void)testRunner
{
  FBWebServer *webServer = [[FBWebServer alloc] init];
  webServer.delegate = self;
  //[self dismissAlerts];
  [self handleAlertIfExists];
  [self handleAppstoreAlert];
  [webServer startServing];
}

#pragma mark - FBWebServerDelegate

- (void)webServerDidRequestShutdown:(FBWebServer *)webServer
{
  [webServer stopServing];
}

@end

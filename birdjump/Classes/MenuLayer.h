//
//  MenuLayer.h
//  birdjump
//
//  Created by Eric on 12-11-20.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//
#import "GCHelper.h"
#import "MyCustomButton.h"
#import <StoreKit/StoreKit.h>
@interface MenuLayer : MyBaseLayer<GCHelperDelegate,SKProductsRequestDelegate>
+(id) scene;
@end

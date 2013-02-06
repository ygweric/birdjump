//
//  InAppPurchaseManager.h
//  birdjump
//
//  Created by Eric on 12-12-10.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <StoreKit/StoreKit.h>
#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate>
{
    SKProduct *proUpgradeProduct;
    SKProductsRequest *productsRequest;
}
- (void)requestProUpgradeProductData;
@end

//
//  MyStoreObserver.m
//  birdjump
//
//  Created by Eric on 12-12-13.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "MyStoreObserver.h"

@implementation MyStoreObserver
//方法在新交易被创建或更新时都会被调用
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}
// observer在用户成功购买后提供相应的product
- (void) completeTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"completeTransaction----");
    // 应用需要实现这两个方法：记录交易、提供内容
    [self recordTransaction: transaction];
    [self provideContent: transaction.payment.productIdentifier];
    // 从payment队列中删除交易
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
-(void)recordTransaction:(SKPaymentTransaction *)transaction{
    //TODO
}
-(void)provideContent:(NSString*)productIdentifier{
    //TODO
    
}
//处理还原购买，结束交易
- (void) restoreTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"restoreTransaction----");
    [self recordTransaction:transaction];
    [self provideContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
//处理失败购买，结束交易
- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"failedTransaction----");
    if (transaction.error.code!= SKErrorPaymentCancelled)
    {
        // 可以显示一个错误（可选的）
        NSLog(@"---transaction.error.code:%d",transaction.error.code);
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

@end

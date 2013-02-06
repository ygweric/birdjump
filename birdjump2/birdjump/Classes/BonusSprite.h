//
//  CoinSprite.h
//  birdjump
//
//  Created by Eric on 12-11-8.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "GameLayer.h"

/*
 bonus泛指所有对bird有奖惩或其它影响的sprite
 包括跳跃平台，金币等
 */

@interface BonusSprite : CCSprite
@property BonusType bonusType;
+(void)initSpriteSheet:(CCNode*)layer;
+(void)initSpriteSheet:(CCNode*)layer texture:(CCTexture2D*) texture;
+ (id) BonusWithinLayer:(CCNode *)layer bType:(BonusType)bType bTag:(int)bTag;
+(CCAction*)createAnimationWithFrameNames:(NSArray*) animFrameNames;
+(CCAction*)getActionByBonusType:(int)bType;
+ (NSArray *)getAnimFrameByBonusType:(int)bType ;
@end

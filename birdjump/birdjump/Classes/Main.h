#import "cocos2d.h"

//#define RESET_DEFAULTS
//帧频率
#define kFPS 60

//app中云的总数目
#define kNumClouds			12

//最大/小台阶相距步长
#define kMinPlatformStep	50
#define kMaxPlatformStep	300

//台阶数量
#define kNumPlatforms		10

#define kPlatformTopPadding 10


//奖励的距离
#define kMinBonusStep		30
#define kMaxBonusStep		50

enum {
	kSpriteManager = 0,
	kBird,
	kScoreLabel,
    //kNumClouds个cloud的第一个tag
	kCloudsStartTag = 100,
	kPlatformsStartTag = 200,
	kBonusStartTag = 300
};

enum {
    //奖励的分数
	kBonus5 = 0,
	kBonus10,
	kBonus50,
	kBonus100,
	kNumBonuses
};

@interface Main : CCLayer
{
	int currentCloudTag;
}
- (void)resetClouds;
- (void)resetCloud;
- (void)step:(ccTime)dt;
@end

#import "cocos2d.h"
#import "Main.h"

@interface Game : Main
{
	CGPoint bird_pos;
	ccVertex2F bird_vel; //速率
	ccVertex2F bird_acc; //加速度

	float currentPlatformY;
	int currentPlatformTag;
	float currentMaxPlatformStep;
	int currentBonusPlatformIndex;
	int currentBonusType;
	int platformCount;
	
	BOOL gameSuspended;
	BOOL birdLookingRight;
	
	int score;
}

+ (CCScene *)scene;

@end

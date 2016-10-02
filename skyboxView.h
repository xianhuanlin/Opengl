//
//  skyboxView.h

//  Created by lin xianhuan on 2016/10/2.
//  Copyright © 2016年 lin xianhuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface skyboxView :UIView

// @ .png
//faces.push_back(right);
//faces.push_back(left);
//faces.push_back(up);
//faces.push_back(down);
//faces.push_back(back);
//faces.push_back(front);

- (void)loadSkyBox:(NSArray*)dic;

@end

//
//  FKHiddenDisclosureIndicatorAccessoryField.m
//  WestJet Cares
//
//  Created by Sam Lu on 9/26/12.
//  Copyright (c) 2012 WestJet. All rights reserved.
//

#import "FKHiddenDisclosureIndicatorAccessoryField.h"

@implementation FKHiddenDisclosureIndicatorAccessoryField

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.detailTextLabel.text = nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleDefault;
}

@end

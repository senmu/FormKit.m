//
// Created by Bruno Wernimont on 2012
// Copyright 2012 FormKit
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FKTextViewField.h"



////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation FKTextViewField

@synthesize textView = _textView;

////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _textView = [[UITextView alloc] init];
        [_textView setBackgroundColor:[UIColor clearColor]];
        [_textView setFont:[UIFont systemFontOfSize:16.0]];
        [self.contentView addSubview:self.textView];
        [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, kTextViewCellHeight)];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.textView.text = nil;
    self.textView.delegate = nil;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x,10,self.textLabel.frame.size.width,self.textLabel.frame.size.height);
    self.textView.frame = CGRectMake(2, self.textLabel.frame.origin.y + self.textLabel.frame.size.height,
                                      self.contentView.frame.size.width - 4, self.contentView.frame.size.height - self.textLabel.frame.size.height - 10);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleValue1;
}


@end

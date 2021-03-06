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

#import "FKFormMapper.h"

#import "FKFormMapping.h"
#import "FKFormAttributeMapping.h"
#import "FKFields.h"
#import "NSObject+FKFormAttributeMapping.h"
#import "FKFormModel.h"
#import "FKSectionObject.h"
#import "UITableViewCell+FormKit.h"
#import "FKFormAttributeValidation.h"

#import "PrettyKit.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface FKFormMapper ()

@property (nonatomic, strong) NSArray *sections;

- (void)mapAttributeMapping:(FKFormAttributeMapping *)attributeMapping
                      value:(id)value
                  withField:(UITableViewCell *)field;

- (FKSimpleField *)cellWithAttributeMapping:(FKFormAttributeMapping *)attributeMapping sourceClass:(Class)sourceClass;

- (Class)classFromSourcePropertyAtIndexPath:(NSIndexPath *)indexPath keyPath:(NSString *)keyPath;

- (id)valueOfObjectForKeyPath:(NSString *)keyPath;

- (void)splitFieldsIntoSections;

- (NSString *)formattedStringDate:(NSDate *)date usingFormat:(NSString *)dateFormat;

/**
 Converts an object property to a string that can be displayed in a label.
 */
- (id)convertValueToStringIfNeeded:(id)value attributeMapping:(FKFormAttributeMapping *)attributeMapping;

/**
 Converts a string value from a text field to the correspondig object value type.
 
 This method is called before setting a value in the model.
 
 @see convertValueToStringIfNeeded:attributeMapping:
 */
- (id)convertValueToObjectPropertyTypeIfNeeded:(NSString*)value attributeMapping:(FKFormAttributeMapping *)attributeMapping;

- (id)cellForClass:(Class)cellClass;

/**
 Creates a keyboard toolbar
 */
- (UIToolbar*)createKeyboardToolbar;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation FKFormMapper

@synthesize formMapping = _formMapping;
@synthesize tableView = _tableView;
@synthesize object = _object;
@synthesize titles = _titles;
@synthesize sections = _sections;


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFormMapping:(FKFormMapping *)formMapping
                tabelView:(UITableView *)tableView
                   object:(id)object
                formModel:(FKFormModel *)formModel {
    
    self = [super init];
    
    if (self) {
        _formModel = formModel; // weak ivar
        _formMapping = formMapping;
        _tableView = tableView;
        _object = object;
        [self splitFieldsIntoSections];
    }
    
    return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfSections {
    return self.formMapping.sectionTitles.count;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[self.sections objectAtIndex:section] count];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)titleForHeaderInSection:(NSInteger)sectionIndex {
    FKSectionObject *section = [self.titles objectAtIndex:sectionIndex];
    return section.headerTitle;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)titleForFooterInSection:(NSInteger)sectionIndex {
    FKSectionObject *section = [self.titles objectAtIndex:sectionIndex];
    return section.footerTitle;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FKFormAttributeMapping *attributeMapping = [self attributeMappingAtIndexPath:indexPath];
    Class sourceClass = [self classFromSourcePropertyAtIndexPath:indexPath keyPath:attributeMapping.attribute];
    PrettyTableViewCell *field = [self cellWithAttributeMapping:attributeMapping sourceClass:sourceClass];
    
    [field prepareForTableView:self.tableView indexPath:indexPath];
    
    if (FKFormAttributeMappingTypeCustomCell == attributeMapping.type) {
        if (nil != attributeMapping.willDisplayCellBlock) {
            attributeMapping.willDisplayCellBlock(field, self.object, indexPath);
        }
        
    } else {
        id value = [self valueForAttributeMapping:attributeMapping];
        [self mapAttributeMapping:attributeMapping value:value withField:field];
        field.textLabel.text = attributeMapping.title;
        if (![field.reuseIdentifier isEqualToString:@"FKSaveButtonField"]) {
            if ([self.formModel.invalidAttributes containsObject:attributeMapping.attribute]) {
                field.textLabel.textColor = self.formModel.validationErrorColor;
            } else {
                field.textLabel.textColor = self.formModel.validationNormalColor;
            }
        }
    }
    
    return field;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (FKFormAttributeMapping *)attributeMappingAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)valueForAttributeMapping:(FKFormAttributeMapping *)attributeMapping {
    return [self valueOfObjectForKeyPath:attributeMapping.attribute];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setValue:(id)value forAttributeMapping:(FKFormAttributeMapping *)attributeMapping {
    [self.object setValue:value forKeyPath:attributeMapping.attribute];
    
    FKFormAttributeValidation *attributeValidation = [self.formMapping.attributeValidations objectForKey:attributeMapping.attribute];
    
    if (nil != attributeValidation) {
        BOOL isValueValid = attributeValidation.valueValidBlock(value, self.object);
        
        NSMutableSet *invalidAttributes = [NSMutableSet setWithSet:self.formModel.invalidAttributes];
        
        if ([invalidAttributes containsObject:attributeMapping.attribute]) {
            [invalidAttributes removeObject:attributeMapping.attribute];
        }
        
        if (NO == isValueValid) {
            [invalidAttributes addObject:attributeMapping.attribute];
        }
        
        self.formModel.invalidAttributes = invalidAttributes;
        
        [self.formModel reloadRowWithIdentifier:attributeMapping.attribute];
    }
    
    if (nil != self.formModel.didChangeValueBlock) {
        self.formModel.didChangeValueBlock([self.formModel object], value, attributeMapping.attribute);
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Actions


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didPressSave:(id)sender {
    self.formMapping.saveAttribute.saveBtnHandler();
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Getters and setters


////////////////////////////////////////////////////////////////////////////////////////////////////
- (FKFormModel *)formModel {
    return _formModel;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)formattedStringDate:(NSDate *)date usingFormat:(NSString *)dateFormat {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    [formatter setCalendar:cal];
    [formatter setLocale:[NSLocale currentLocale]];
    NSString *stringDate = [formatter stringFromDate:date];
    return stringDate;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mapAttributeMapping:(FKFormAttributeMapping *)attributeMapping
                      value:(id)value
                  withField:(UITableViewCell *)field {
    
    id convertedValue = [self convertValueToStringIfNeeded:value attributeMapping:attributeMapping];
    
    // Value attribution
    if ([field isKindOfClass:[FKTextField class]]) {
        [(FKTextField *)field textField].text = convertedValue;
        [(FKTextField *)field textField].placeholder = attributeMapping.placeholderText;
        
    } else if ([field isKindOfClass:[FKSwitchField class]] && [convertedValue isKindOfClass:[NSNumber class]]) {
        UISwitch *switchControl = [(FKSwitchField *)field switchControl];
        switchControl.on = [(NSNumber *)convertedValue boolValue];
        switchControl.formAttributeMapping = attributeMapping;
        [switchControl addTarget:self
                          action:@selector(switchFieldValueDidChange:)
                forControlEvents:UIControlEventValueChanged];
        
    } else if ([field isKindOfClass:[FKSliderField class]]) {
        field.detailTextLabel.text = attributeMapping.sliderValueBlock(value);
        UISlider *sliderControl = [(FKSliderField *)field slider];
        [sliderControl setMinimumValue:attributeMapping.minValue];
        [sliderControl setMaximumValue:attributeMapping.maxValue];
        sliderControl.value = [(NSNumber *)convertedValue floatValue];
        sliderControl.formAttributeMapping = attributeMapping;
        [sliderControl addTarget:self
                          action:@selector(sliderFieldValueDidChange:)
                forControlEvents:UIControlEventValueChanged];
        
    } else if ([field isKindOfClass:[FKSaveButtonField class]]) {
        [(FKSaveButtonField *)field setTitle:attributeMapping.title];
        
    } else if ([field isKindOfClass:[FKButtonField class]]) {
        field.textLabel.text = attributeMapping.title;
        field.accessoryType = attributeMapping.accesoryType;
        
    } else if ([field isKindOfClass:[FKTextViewField class]]) {
        [(FKTextViewField *)field textView].text = convertedValue;
        
    } else {
        if (![convertedValue isKindOfClass:[NSString class]]) {
            convertedValue = [convertedValue description];
        }
        
        field.detailTextLabel.text = convertedValue;
        
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (FKSimpleField *)cellWithAttributeMapping:(FKFormAttributeMapping *)attributeMapping
                                sourceClass:(Class)sourceClass {
    
    FKSimpleField *field = nil;
    FKFormAttributeMappingType type = attributeMapping.type;

    if (type == FKFormAttributeMappingTypeText || type == FKFormAttributeMappingTypeTextCap) {
        field = [self cellForClass:_formMapping.textFieldClass];
        [[(FKTextField *)field textField] setDelegate:self];
        [[(FKTextField *)field textField] setFormAttributeMapping:attributeMapping];
        [[(FKTextField *)field textField] setKeyboardType:attributeMapping.keyboardType];
        [[(FKTextField *)field textField] setInputAccessoryView:[self createKeyboardToolbar]];
        
        if (type == FKFormAttributeMappingTypeTextCap) {
            [[(FKTextField *)field textField] setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
            [[(FKTextField *)field textField] setAutocorrectionType:UITextAutocorrectionTypeNo];
        }
        
    } else if (type == FKFormAttributeMappingTypeTextView) {   
        field = [self cellForClass:_formMapping.textViewClass];
        [[(FKTextViewField *)field textView] setDelegate:self];
        [[(FKTextViewField *)field textView] setFormAttributeMapping:attributeMapping];
        [[(FKTextViewField *)field textView] setKeyboardType:attributeMapping.keyboardType];
        [[(FKTextViewField *)field textView] setInputAccessoryView:[self createKeyboardToolbar]];

    } else if (type == FKFormAttributeMappingTypeNumeric || type == FKFormAttributeMappingTypePhone || type == FKFormAttributeMappingTypeEmail) {
        field = [self cellForClass:_formMapping.textFieldClass];
        [[(FKTextField *)field textField] setDelegate:self];
        [[(FKTextField *)field textField] setFormAttributeMapping:attributeMapping];
        [[(FKTextField *)field textField] setKeyboardType:attributeMapping.keyboardType];
        [[(FKTextField *)field textField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [[(FKTextField *)field textField] setInputAccessoryView:[self createKeyboardToolbar]];
        
    } else if (type == FKFormAttributeMappingTypeFloat) {    
        field = [self cellForClass:_formMapping.floatFieldClass];
        [[(FKFloatField *)field textField] setDelegate:self];
        [[(FKFloatField *)field textField] setFormAttributeMapping:attributeMapping];
        [[(FKFloatField *)field textField] setKeyboardType:attributeMapping.keyboardType];
        [[(FKTextField *)field textField] setInputAccessoryView:[self createKeyboardToolbar]];

    } else if (type == FKFormAttributeMappingTypeInteger) {
        field = [self cellForClass:_formMapping.integerFieldClass];
        [[(FKIntegerField *)field textField] setDelegate:self];
        [[(FKIntegerField *)field textField] setFormAttributeMapping:attributeMapping];
        [[(FKIntegerField *)field textField] setKeyboardType:attributeMapping.keyboardType];
        [[(FKIntegerField *)field textField] setInputAccessoryView:[self createKeyboardToolbar]];
        
    } else if (type == FKFormAttributeMappingTypeLabel) {
        field = [self cellForClass:_formMapping.labelFieldClass];
        
    } else if (type == FKFormAttributeMappingTypePassword) {
        field = [self cellForClass:_formMapping.passwordFieldClass];
        [[(FKPasswordTextField *)field textField] setDelegate:self];
        [[(FKPasswordTextField *)field textField] setFormAttributeMapping:attributeMapping];
        [[(FKPasswordTextField *)field textField] setKeyboardType:attributeMapping.keyboardType];
        [[(FKPasswordTextField *)field textField] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        [[(FKPasswordTextField *)field textField] setInputAccessoryView:[self createKeyboardToolbar]];

    } else if (type == FKFormAttributeMappingTypeBoolean) {
        field = [self cellForClass:_formMapping.switchFieldClass];
        
    } else if (type == FKFormAttributeMappingTypeSaveButton) {
        field = [self cellForClass:_formMapping.saveButtonFieldClass];
        
    } else if (type == FKFormAttributeMappingTypeButton) {
        field = [self cellForClass:_formMapping.buttonFieldClass];
        
    } else if ((type == FKFormAttributeMappingTypeSelect && attributeMapping.showInPicker) ||
               type == FKFormAttributeMappingTypeTime ||
               type == FKFormAttributeMappingTypeDate ||
               type == FKFormAttributeMappingTypeDateTime) {
        field = [self cellForClass:_formMapping.labelFieldClass];
        
    } else if (type == FKFormAttributeMappingTypeSelect && !attributeMapping.showInPicker) {
        field = [self cellForClass:_formMapping.disclosureIndicatorAccessoryField];
        
    } else if (type == FKFormAttributeMappingTypeBigText) {
        //field = [self cellForClass:_formMapping.disclosureIndicatorAccessoryField];
        field = [self cellForClass:_formMapping.hiddenDisclosureIndicatorAccessoryField];
        
    } else if (type == FKFormAttributeMappingTypeCustomCell) {
        field = [self cellForClass:attributeMapping.customCell];
        
    } else if (type == FKFormAttributeMappingTypeSlider) {
        field = [self cellForClass:_formMapping.sliderFieldClass];
        
    } else {
        field = [self cellForClass:_formMapping.labelFieldClass];
    }
    
    return field;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)convertValueToStringIfNeeded:(id)value attributeMapping:(FKFormAttributeMapping *)attributeMapping {
    id convertedValue = value;
    
    if (attributeMapping.type == FKFormAttributeMappingTypeInteger) {
        NSInteger integerValue = [(NSNumber *)value integerValue];
        convertedValue = [NSString stringWithFormat:@"%d", integerValue];
        
    } else if (attributeMapping.type == FKFormAttributeMappingTypeFloat) {
        float floatValue = [(NSNumber *)value floatValue];
        convertedValue = [NSString stringWithFormat:@"%f", floatValue];
        
    } else if (attributeMapping.type == FKFormAttributeMappingTypeDateTime ||
               attributeMapping.type == FKFormAttributeMappingTypeDate ||
               attributeMapping.type == FKFormAttributeMappingTypeTime) {
        
        if (nil != attributeMapping.dateFormat) {
            convertedValue = [self formattedStringDate:value usingFormat:attributeMapping.dateFormat];
        } else if (nil != attributeMapping.dateFormatBlock) {
            NSString *dataFormat = attributeMapping.dateFormatBlock();
            convertedValue = [self formattedStringDate:value usingFormat:dataFormat];
        } else {
            convertedValue = [value description];
        }
        
    } else if (attributeMapping.type == FKFormAttributeMappingTypeSelect) {
        convertedValue = attributeMapping.labelValueBlock(value, self.object);
        
    }
    
    return convertedValue;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)convertValueToObjectPropertyTypeIfNeeded:(NSString*)value attributeMapping:(FKFormAttributeMapping *)attributeMapping {
    id convertedValue = value;
    
    if (attributeMapping.type == FKFormAttributeMappingTypeInteger) {
        NSInteger integerValue = [value integerValue];
        convertedValue = [NSNumber numberWithInteger:integerValue];
    } else if (attributeMapping.type == FKFormAttributeMappingTypeFloat) {
        float floatValue = [value floatValue];
        convertedValue = [NSNumber numberWithFloat:floatValue];
    } else if (attributeMapping.type == FKFormAttributeMappingTypeDateTime ||
               attributeMapping.type == FKFormAttributeMappingTypeDate ||
               attributeMapping.type == FKFormAttributeMappingTypeTime) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];

        if (nil != attributeMapping.dateFormat) {
            [formatter setDateFormat:attributeMapping.dateFormat];
            convertedValue = [formatter dateFromString:value];
        } else if (nil != attributeMapping.dateFormatBlock) {
            NSString *dateFormat = attributeMapping.dateFormatBlock();
            [formatter setDateFormat:dateFormat];
            convertedValue = [formatter dateFromString:value];
        } else {
            convertedValue = [formatter dateFromString:value];
        }
        
        
    } else if (attributeMapping.type == FKFormAttributeMappingTypeSelect) {
        convertedValue = attributeMapping.labelValueBlock(value, self.object);
        
    }
    
    return convertedValue;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (Class)classFromSourcePropertyAtIndexPath:(NSIndexPath *)indexPath keyPath:(NSString *)keyPath {
    return [NSObject class]; // Unused at the moment
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)valueOfObjectForKeyPath:(NSString *)keyPath {
    id value = nil;
    
    @try {
        value = [self.object valueForKeyPath:keyPath];
    }
    @catch (NSException *exception) {
        NSLog(@"Error FormKitFormMapping keyPath %@ doesn't exist for object name %@",
              keyPath, NSStringFromClass([self.object class]));
        
        value = nil;
    }
    
    return value;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSIndexPath *)indexPathOfAttributeMapping:(FKFormAttributeMapping *)attributeMapping {
    __block NSUInteger sectionIndex = 0;
    __block NSUInteger rowIndex = 0;
    __block BOOL found = NO;
    
    [self.sections enumerateObjectsUsingBlock:^(NSArray *sectionAttributeMappings, NSUInteger currentSectionIndex, BOOL *stop) {
        [sectionAttributeMappings enumerateObjectsUsingBlock:^(id obj, NSUInteger currentAttributeMappingIndex, BOOL *stop) {
            if (obj == attributeMapping) {
                sectionIndex = currentSectionIndex;
                rowIndex = currentAttributeMappingIndex;
                *stop = YES;
            }
        }];
        
        if (found) {
            *stop = YES;
        }
    }];
    
    return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)splitFieldsIntoSections {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    
    [self.formMapping.fieldsOrder enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {
        if ([self.formMapping.sectionTitles objectForKey:identifier]) {
            [titles addObject:[self.formMapping.sectionTitles objectForKey:identifier]];
            [sections addObject:[NSMutableArray array]];
        } else if ([self.formMapping.attributeMappings objectForKey:identifier]) {
            NSMutableArray *currentSection = [sections lastObject];
            [currentSection addObject:[self.formMapping.attributeMappings objectForKey:identifier]];
        }
    }];
        
    _titles = [NSArray arrayWithArray:titles];
    self.sections = [NSArray arrayWithArray:sections];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FKFormAttributeMapping *attributeMapping = [self attributeMappingAtIndexPath:indexPath];
    if (attributeMapping.type == FKFormAttributeMappingTypeTextView) {
        return kTextViewCellHeight;
    }
    return attributeMapping.rowHeight > 0 ? attributeMapping.rowHeight : self.tableView.rowHeight;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIEvent


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)switchFieldValueDidChange:(UISwitch *)sender {
    [self setValue:[NSNumber numberWithBool:sender.isOn] forAttributeMapping:sender.formAttributeMapping];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)sliderFieldValueDidChange:(UISlider *)sender {
    [self setValue:[NSNumber numberWithFloat:sender.value] forAttributeMapping:sender.formAttributeMapping];
    [self.formModel reloadRowWithAttributeMapping:sender.formAttributeMapping];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextFieldDelegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textFieldDidEndEditing:(UITextField *)textField {
    id value = [self convertValueToObjectPropertyTypeIfNeeded:textField.text attributeMapping:textField.formAttributeMapping];
    [self setValue:value forAttributeMapping:textField.formAttributeMapping];
    [self.formModel reloadRowWithAttributeMapping:textField.formAttributeMapping];
}


////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UITextViewDelegate


////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)textViewDidEndEditing:(UITextView *)textView {
    [self setValue:textView.text forAttributeMapping:textView.formAttributeMapping];
    [self.formModel reloadRowWithAttributeMapping:textView.formAttributeMapping];
}



////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)cellForClass:(Class)cellClass {
    return [cellClass fk_cellForTableView:self.tableView
                            configureCell:self.formModel.configureCellsBlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
- (UIToolbar*)createKeyboardToolbar {
    // Create the 'next' button
    UIBarButtonItem* nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:_formModel
                                                                  action:@selector(nextField:)];

    // Create the 'previous' button'
    UIBarButtonItem* previousButton = [[UIBarButtonItem alloc] initWithTitle:@"Previous"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:_formModel
                                                                      action:@selector(previousField:)];

    // Create some flexible space
    UIBarButtonItem* extraSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:nil
                                                                                action:nil];

    // Create the 'done' button
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:_formModel
                                                                  action:@selector(resignKeyboard:)];

    // Set the button widths
    nextButton.width = 70.0f;
    previousButton.width = 70.0f;

    // Create the toolbar and assign the buttons
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 44)];
    keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
    [keyboardToolbar setItems:[[NSArray alloc] initWithObjects: previousButton, nextButton, extraSpace, doneButton, nil]];

    return keyboardToolbar;
}


@end

/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

/**
 Fetching Fixtures, causing test failures if they cannot be obtained.
 */
@interface XCTestCase (FBXCTestBootstrapFixtures)

/**
 An iOS Unit Test Bundle.
 */
+ (NSBundle *)iosUnitTestBundleFixture;

/**
 An macOS Unit Test Bundle.
 */
+ (NSBundle *)macUnitTestBundleFixture;

@end

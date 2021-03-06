/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSimulatorLaunchedApplication.h"

#import "FBSimulator+Private.h"
#import "FBSimulator.h"
#import "FBSimulatorProcessFetcher.h"

@interface FBSimulatorLaunchedApplication ()

@property (nonatomic, weak, nullable, readonly) FBSimulator *simulator;

@end

@implementation FBSimulatorLaunchedApplication

@synthesize applicationTerminated = _applicationTerminated;
@synthesize processIdentifier = _processIdentifier;

#pragma mark Initializers

+ (FBFuture<FBSimulatorLaunchedApplication *> *)applicationWithSimulator:(FBSimulator *)simulator configuration:(FBApplicationLaunchConfiguration *)configuration stdOut:(id<FBProcessFileOutput>)stdOut stdErr:(id<FBProcessFileOutput>)stdErr launchFuture:(FBFuture<NSNumber *> *)launchFuture
{
  return [launchFuture
    onQueue:simulator.workQueue map:^(NSNumber *processIdentifierNumber) {
      pid_t processIdentifier = processIdentifierNumber.intValue;
      FBFuture<NSNull *> *terminationFuture = [FBSimulatorLaunchedApplication terminationFutureForSimulator:simulator processIdentifier:processIdentifier];
      FBSimulatorLaunchedApplication *operation = [[self alloc] initWithSimulator:simulator configuration:configuration stdOut:stdOut stdErr:stdErr processIdentifier:processIdentifier terminationFuture:terminationFuture];
      return operation;
    }];
}

- (instancetype)initWithSimulator:(FBSimulator *)simulator configuration:(FBApplicationLaunchConfiguration *)configuration stdOut:(id<FBProcessFileOutput>)stdOut stdErr:(id<FBProcessFileOutput>)stdErr processIdentifier:(pid_t)processIdentifier terminationFuture:(FBFuture<NSNull *> *)terminationFuture
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _simulator = simulator;
  _configuration = configuration;
  _stdOut = stdOut;
  _stdErr = stdErr;
  _processIdentifier = processIdentifier;
  _applicationTerminated = [terminationFuture
    onQueue:simulator.workQueue chain:^(FBFuture *future) {
      return [[self performTeardown] chainReplace:future];
    }];
  return self;
}

#pragma mark Helpers

+ (FBFuture<NSNull *> *)terminationFutureForSimulator:(FBSimulator *)simulator processIdentifier:(pid_t)processIdentifier
{
  return [[[FBDispatchSourceNotifier
    processTerminationFutureNotifierForProcessIdentifier:processIdentifier]
    mapReplace:NSNull.null]
    onQueue:simulator.workQueue respondToCancellation:^{
      [[FBProcessTerminationStrategy
        strategyWithProcessFetcher:simulator.processFetcher.processFetcher workQueue:simulator.workQueue logger:simulator.logger]
        killProcessIdentifier:processIdentifier];
      return FBFuture.empty;
    }];
}

#pragma mark NSObject

- (NSString *)description
{
  return [NSString stringWithFormat:@"Application Operation %@ | pid %d | State %@", self.configuration.description, self.processIdentifier, self.applicationTerminated];
}

#pragma mark Private

- (FBFuture<NSNull *> *)performTeardown
{
  return [[FBFuture
    futureWithFutures:@[
      [self.stdOut stopReading],
      [self.stdErr stopReading],
    ]]
    mapReplace:NSNull.null];
}

@end

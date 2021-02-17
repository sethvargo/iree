// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef IREE_DIALECT_FLOW_INTERFACES
#define IREE_DIALECT_FLOW_INTERFACES

include "iree/compiler/Dialect/IREE/IR/IREEBase.td"

//===----------------------------------------------------------------------===//
// IREE::Flow::ClosureOpInterface
//===----------------------------------------------------------------------===//

def FLOW_ClosureOpInterface : OpInterface<"ClosureOpInterface"> {
  let description = [{
    Interface for ops that follow the Flow dialect closure semantics (explicit
    captures, dynamic-shape awareness, and normal operand/result SSA behavior).

    Implementing this interface enables optimizations that perform manipulation
    across the closure capture boundary (outside of the op <-> regions within
    the op).
  }];

  let methods = [
    InterfaceMethod<
      [{Returns the body region of the closure (may have multiple blocks).}],
      "Region &", "getClosureBodyRegion", (ins), /*methodBody=*/[{}],
      /*defaultImplementation=*/[{
        return this->getOperation()->getRegion(0);
      }]
    >,
    InterfaceMethod<
      [{Returns all closure operand values.}],
      "Operation::operand_range", "getClosureOperands", (ins)
    >,
    InterfaceMethod<
      [{Returns all closure result values.}],
      "Operation::result_range", "getClosureResults", (ins)
    >,
    InterfaceMethod<
      [{Returns true if the given operation can exist in the closure.}],
      "bool", "canClosureContainOp", (ins "Operation *":$op)
    >,
    InterfaceMethod<[{
      Clones the op while removing specified operands and results.
      The body of the op will be transferred to the new op and the entry block
      will have its arguments removed.

      The returned op will be free standing. Callers must insert it into a block
      where desired (most often just replacing the current op).
    }], "ClosureOpInterface", "cloneReplacementExcludingOperandsAndResults",
      (ins "ArrayRef<unsigned>":$excludedOperandIndices,
           "ArrayRef<unsigned>":$excludedResultIndices)
    >,
  ];
}

//===----------------------------------------------------------------------===//
// IREE::Flow::StreamableOpInterface
//===----------------------------------------------------------------------===//

def FLOW_StreamableOp : OpInterface<"StreamableOpInterface"> {
  let description = [{
    Interface for ops that can be used within a stream.

    Some ops can exist both within a stream and outside of a stream. This allows
    optimizations to place certain ops such that they are performed in a
    synchronous (outside of a stream) or asynchronous (inside of a stream)
    fashion.

    The goal of the stream forming process is to move as many operations that
    can be used within a stream into one and only using non-streamed ops as a
    last resort.
  }];

  let methods = [
    InterfaceMethod<
      [{Returns true if the op is transfer operation (as defined by the HAL).}],
      "bool", "isTransfer", (ins)
    >,
  ];
}

#endif  // IREE_DIALECT_FLOW_INTERFACES

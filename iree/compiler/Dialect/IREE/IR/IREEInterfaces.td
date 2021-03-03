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

#ifndef IREE_DIALECT_IREE_INTERFACES
#define IREE_DIALECT_IREE_INTERFACES

include "iree/compiler/Dialect/IREE/IR/IREEBase.td"

//===----------------------------------------------------------------------===//
// IREE::TiedOpInterface
//===----------------------------------------------------------------------===//

def IREE_TiedOpInterface : OpInterface<"TiedOpInterface"> {
  let description = [{
    An operation that "ties" one or more results to its operands indicating
    that the result is directly related to the operand in an operation-defined
    way. Results are still SSA values distinct from the operands and the tie is
    strictly a relationship relevant to transformations and not something that
    modifies IR definitions.

    Example:
      An operation on tensors that wants to indicate that the storage for a
      result should alias the storage for an operand, performing an "in-place"
      operation. Since tensors are still used there is no hard requirement that
      uses of the result SSA value alias the operand; a copy may still be
      introduced.

      See: flow.dispatch.workgroups

    Example:
      An operation on buffers that wants to encode activity on the buffer in IR
      (such as a barrier, a transfer operation, etc) such that the SSA use-def
      chain is representing the state of the buffer at various points in time
      but that the underlying buffers are all tied together.

      See: hal.stream.barrier

    The default implementations use an attribute on the op to store the
    relationship:
      `OptionalAttr<IREE_TiedOpStorageAttr>:$tied_operands`
  }];

  let methods = [
    InterfaceMethod<[{
      Returns the set of operands that results may be tied to.
      }],
      "std::pair<unsigned, unsigned>", "getTiedOperandsIndexAndLength", (ins),
      [{}],
      [{
        return {0, $_op.getNumOperands()};
      }]
    >,
    InterfaceMethod<[{
      Walks the SSA use-def chain to find the first defined value reachable
      from the given value by traversing tied ops. Note that the returned
      value may be a block argument and have no defining op.
      }],
      "Value", "getTiedResult",
      (ins "unsigned":$resultIndex),
      [{}],
      [{
        return IREE::TiedOpInterface::findTiedBaseValue($_op.getResult(resultIndex));
      }]
    >,
    InterfaceMethod<[{
      Returns the operand tied to the given result of the op or nullptr if none.
      }],
      "Value", "getTiedResultOperand",
      (ins "Value":$result),
      [{}],
      [{
        auto resultIndex = std::distance($_op->getResults().begin(),
                                         llvm::find($_op->getResults(), result));
        auto operandIndex = IREE::detail::getTiedResultOperandIndex($_op, resultIndex);
        return operandIndex.hasValue() ?
            $_op.getOperand(operandIndex.getValue()) :
            nullptr;
      }]
    >,
    InterfaceMethod<[{
      Returns the operand index tied to the given result index, if any.
      }],
      "::llvm::Optional<unsigned>", "getTiedResultOperandIndex",
      (ins "unsigned":$resultIndex),
      [{}],
      [{
        return IREE::detail::getTiedResultOperandIndex($_op, resultIndex);
      }]
    >,
    InterfaceMethod<[{
      Sets the operand index tied to the given result index, if any.
      }],
      "void", "setTiedResultOperandIndex",
      (ins "unsigned":$resultIndex, "::llvm::Optional<unsigned>":$operandIndex),
      [{}],
      [{
        return IREE::detail::setTiedResultOperandIndex($_op, resultIndex, operandIndex);
      }]
    >,
    InterfaceMethod<[{
      Returns an array containing the tied result operand indices with -1
      indicating that a result is not tied.
      }],
      "SmallVector<int64_t, 4>", "getTiedResultOperandIndices", (ins),
      [{}],
      [{
        return IREE::detail::getTiedResultOperandIndices($_op);
      }]
    >,
  ];

  let extraClassDeclaration = [{
    static StringRef getStorageAttrName() { return "tied_operands"; }

    // Walks the SSA use-def chain to find the first defined value reachable
    // from the given value by traversing tied ops. Note that the returned
    // value may be a block argument and have no defining op.
    static Value findTiedBaseValue(Value derivedValue);
  }];

  let verify = [{
    return IREE::detail::verifyTiedOp($_op);
  }];
}

#endif  // IREE_DIALECT_IREE_INTERFACES

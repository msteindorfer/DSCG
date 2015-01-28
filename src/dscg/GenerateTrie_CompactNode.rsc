/**
 * Copyright (c) 2014 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
 */
module dscg::GenerateTrie_CompactNode

import List;

import dscg::Common;

// TODO: remove!!!
str emptyTrieNodeConstantName = "EMPTY_NODE";

str generateCompactNodeClassString(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) {
	abstractMembers = [ bitmapMethod, valmapMethod ];
	concreteMembers = [];
	
	members = abstractMembers + concreteMembers;	
	
	constructorArgs = asFieldList(
		  ts.mutator 
		+ members);

	str className = "<CompactNode(ts.ds)>"; 

	int n = 0; // TODO: remove
	int m = 0; // TODO: remove

	return
	"protected static abstract class <className><Generics(ts.ds, ts.tupleTypes)> extends Abstract<toString(ds)>Node<Generics(ts.ds, ts.tupleTypes)> {
		
		<dec(field(primitive("int"), "HASH_CODE_LENGTH"), constant(primitive("int"), "32"), isStatic = true, isFinal = true)>;
		
		<dec(field(primitive("int"), "BIT_PARTITION_SIZE"), constant(primitive("int"), "<bitPartitionSize>"), isStatic = true, isFinal = true)>;
		<dec(field(primitive("int"), "BIT_PARTITION_MASK"), constant(primitive("int"), "0b<for (i <- [1..bitPartitionSize+1]) {>1<}>"), isStatic = true, isFinal = true)>;
		
		<implOrOverride(ts.CompactNode_mask, generate_bodyOf_mask(ts, ts.CompactNode_mask))>
		<implOrOverride(ts.CompactNode_bitpos, generate_bodyOf_bitpos(ts, ts.CompactNode_bitpos))>		
		
		<dec(ts.CompactNode_nodeMap, asAbstract = true)>
		<dec(ts.CompactNode_dataMap, asAbstract = true)>
		
		<dec(field(primitive("byte"), "SIZE_EMPTY"), 		constant(primitive("byte"), "0b00"), isStatic = true)>;
		<dec(field(primitive("byte"), "SIZE_ONE"), 			constant(primitive("byte"), "0b01"), isStatic = true)>;
		<dec(field(primitive("byte"), "SIZE_MORE_THAN_ONE"),constant(primitive("byte"), "0b10"), isStatic = true)>;

		<dec(ts.CompactNode_convertToGenericNode, asAbstract = true)>

		/**
		 * Abstract predicate over a node\'s size. Value can be either
		 * {@value #SIZE_EMPTY}, {@value #SIZE_ONE}, or
		 * {@value #SIZE_MORE_THAN_ONE}.
		 * 
		 * @return size predicate
		 */
		<dec(ts.CompactNode_sizePredicate, asAbstract = true)>

		@Override
		<dec(ts.CompactNode_getNode, asAbstract = true)>

		boolean nodeInvariant() {
			boolean inv1 = (size() - payloadArity() \>= 2 * (arity() - payloadArity()));
			boolean inv2 = (this.arity() == 0) ? sizePredicate() == SIZE_EMPTY : true;
			boolean inv3 = (this.arity() == 1 && payloadArity() == 1) ? sizePredicate() == SIZE_ONE
							: true;
			boolean inv4 = (this.arity() \>= 2) ? sizePredicate() == SIZE_MORE_THAN_ONE : true;

			boolean inv5 = (this.nodeArity() \>= 0) && (this.payloadArity() \>= 0)
							&& ((this.payloadArity() + this.nodeArity()) == this.arity());

			return inv1 && inv2 && inv3 && inv4 && inv5;
		}

		<implOrOverride(ts.CompactNode_copyAndInsertNode, UNSUPPORTED_OPERATION_EXCEPTION, doOverride = new())>
		
		<implOrOverride(ts.CompactNode_copyAndRemoveNode, UNSUPPORTED_OPERATION_EXCEPTION, doOverride = new())>

		<dec(ts.CompactNode_copyAndSetValue, asAbstract = true)>

		<dec(ts.CompactNode_copyAndInsertValue, asAbstract = true)>
	
		<dec(ts.CompactNode_copyAndRemoveValue, asAbstract = true)>
	
		<dec(ts.CompactNode_copyAndSetNode, asAbstract = true)>
	
		<dec(ts.CompactNode_copyAndMigrateFromInlineToNode, asAbstract = true)>
		
		<dec(ts.CompactNode_copyAndMigrateFromNodeToInline, asAbstract = true)>
		
		/* TODO: specialize removed(..) to remove this method from this interface */
		<implOrOverride(ts.CompactNode_removeInplaceValueAndConvertToSpecializedNode, UNSUPPORTED_OPERATION_EXCEPTION, doOverride = new())>


		<implOrOverride(ts.CompactNode_mergeTwoKeyValPairs, 
			generate_bodyOf_mergeTwoKeyValPairs(ts), annotations = [ UNCHECKED_ANNOTATION() ])>

		<if (false) {>
		<implOrOverride(ts.CompactNode_mergeNodeAndKeyValPair,
			generate_bodyOf_mergeNodeAndKeyValPair(ts))>
		<}>

	'	static final <CompactNode(ts.ds)> <emptyTrieNodeConstantName>;

	'	static {
	'		<if (isOptionEnabled(setup,useSpecialization())) {>
				<emptyTrieNodeConstantName> = new <toString(ds)>0To0Node<ts.classNamePostfix><InferredGenerics(ts.ds, ts.tupleTypes)>(null, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0);
			<} else {>
		 		<emptyTrieNodeConstantName> = <toString(call(ts.BitmapIndexedNode_constructor, 
					argsOverride = (ts.mutator: NULL(),								
								ts.bitmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.bitmapField.\type, "0")), 
								ts.valmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.valmapField.\type, "0")),
								ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { }"),
								ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "0")),
								ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "0"))),
					inferredGenericsStr = "<InferredGenerics(ts.ds, ts.tupleTypes)>"))>;
				
			<}>	
	'	};
	
	<implOrOverride(ts.nodeOf_BitmapIndexedNode,
		"return <toString(call(ts.BitmapIndexedNode_constructor, inferredGenericsStr = InferredGenerics(ts.ds, ts.tupleTypes)))>;")>	
	
	<if (!isOptionEnabled(setup,useSpecialization()) || nBound < nMax) {>
	'	<toString(UNCHECKED_ANNOTATION())>
	'	static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(AtomicReference\<Thread\> mutator) {
	'		return <emptyTrieNodeConstantName>;
	'	}
	<} else {>
	'	// TODO: consolidate and remove
	'	static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(AtomicReference\<Thread\> mutator) {
	'		return nodeOf(mutator, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0);
	'	}
	<}>

	<if (!isOptionEnabled(setup,useSpecialization())) {>
	'	static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(AtomicReference\<Thread\> mutator, <dec(ts.bitmapField)>, <dec(ts.valmapField)>, <dec(nodeTupleArgs(ts))>) {
	'		assert <use(bitmapField)> == 0;	
	'		return <toString(call(ts.nodeOf_BitmapIndexedNode, 
				argsOverride = (ts.bitmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.bitmapField.\type, "0")),						
								ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { <use(nodeTupleArgs(ts))> }"),
								ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "1")),
								ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "0")))))>;
	'	}
	<}>


	<generate_specializationFactoryMethods(ts, setup)>

	<implOrOverride(ts.CompactNode_index2,
		"return <integerOrLongObject(bitPartitionSize)>.bitCount(<useSafeUnsigned(___anybitmapField(bitPartitionSize))> & (bitpos - 1));", doOverride = new())>
	
	<implOrOverride(ts.CompactNode_index3,
		"return (<useSafeUnsigned(___anybitmapField(bitPartitionSize))> == -1) 
			? mask 
			: <toString(call(ts.CompactNode_index2))>;", doOverride = new())>
	
	<implOrOverride(ts.CompactNode_dataIndex, 
		"return <integerOrLongObject(bitPartitionSize)>.bitCount(<useSafeUnsigned(___valmapMethod(bitPartitionSize))> & (bitpos - 1));", doOverride = new())>

	<implOrOverride(ts.CompactNode_nodeIndex,
		"return <integerOrLongObject(bitPartitionSize)>.bitCount(<useSafeUnsigned(___bitmapMethod(bitPartitionSize))> & (bitpos - 1));", doOverride = new())>

	<if(false) {>
//	<toString(ts.keyType)> keyAt(<dec(ts.bitposField)>) {
//		return getKey(dataIndex(bitpos)); 
//	}
//
//	<if (\map() := ts.ds) {>
//	<toString(__returnTypeOf_AbstractNode_getValue(ts.ds, ts.tupleTypes))> valAt(<dec(ts.bitposField)>) {
//		return getValue(dataIndex(bitpos)); 
//	}
//	<}>
	<}>

	<CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeAt(<dec(ts.bitposField)>) {
		return getNode(nodeIndex(bitpos)); 
	}

	<implOrOverride(ts.AbstractNode_containsKey, 		generate_bodyOf_SpecializedBitmapPositionNode_containsKey(n, m, ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.AbstractNode_containsKeyEquiv,	generate_bodyOf_SpecializedBitmapPositionNode_containsKey(n, m, ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.AbstractNode_findByKey, 		generate_bodyOf_SpecializedBitmapPositionNode_findByKey(n, m, ts, setup, equalityDefaultForArguments	))>
	<implOrOverride(ts.AbstractNode_findByKeyEquiv,	generate_bodyOf_SpecializedBitmapPositionNode_findByKey(n, m, ts, setup, equalityComparatorForArguments	))>
	
	<implOrOverride(ts.AbstractNode_updated, 		generate_bodyOf_SpecializedBitmapPositionNode_updated(n, m, ts, setup, equalityDefaultForArguments))>
	<implOrOverride(ts.AbstractNode_updatedEquiv,	generate_bodyOf_SpecializedBitmapPositionNode_updated(n, m, ts, setup, equalityComparatorForArguments))>

	<implOrOverride(ts.AbstractNode_removed, 		generate_bodyOf_SpecializedBitmapPositionNode_removed(n, m, ts, setup, equalityDefaultForArguments, ts.AbstractNode_removed))>
	<implOrOverride(ts.AbstractNode_removedEquiv,	generate_bodyOf_SpecializedBitmapPositionNode_removed(n, m, ts, setup, equalityComparatorForArguments, ts.AbstractNode_removedEquiv))>

	'	/**
	'	 * @return 0 \<= mask \<= 2^BIT_PARTITION_SIZE - 1
	'	 */
	'	static byte recoverMask(<typeToString(chunkSizeToPrimitive(bitPartitionSize))> map, byte i_th) {
	'		assert 1 \<= i_th && i_th \<= <nMax>;
	'		
	'		byte cnt1 = 0;
	'		byte mask = 0;
	'		
	'		while (mask \< <nMax>) {
	'			if ((map & 0x01) == 0x01) {
	'				cnt1 += 1;
	'		
	'				if (cnt1 == i_th) {
	'					return mask;
	'				}
	'			}
	'		
	'			map = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (map \>\> 1);
	'			mask += 1;
	'		}
	'			
	'		assert cnt1 != i_th;
	'		throw new RuntimeException(\"Called with invalid arguments.\");
	'	}

	'	@Override
	'	public String toString() {
	'		final StringBuilder bldr = new StringBuilder();
	'		bldr.append(\'[\');
	'
	'		for (byte i = 0; i \< payloadArity(); i++) {
	'			final byte pos = recoverMask(<use(valmapMethod)>, (byte) (i + 1));
	'			bldr.append(String.format(\"@%d: <intercalate("=", times("%s", size(ts.payloadTuple)))>\", pos, <use(invoke_get_for_payloadTuple(ts.ds, ts.tupleTypes, field("i")))>));
	'
	'			if (!((i + 1) == payloadArity())) {
	'				bldr.append(\", \");
	'			}
	'		}
	'
	'		if (payloadArity() \> 0 && nodeArity() \> 0) {
	'			bldr.append(\", \");
	'		}
	'
	'		for (byte i = 0; i \< nodeArity(); i++) {
	'			final byte pos = recoverMask(<use(bitmapMethod)>, (byte) (i + 1));
	'			bldr.append(String.format(\"@%d: %s\", pos, getNode(i)));
	'
	'			if (!((i + 1) == nodeArity())) {
	'				bldr.append(\", \");
	'			}
	'		}
	'
	'		bldr.append(\']\');
	'		return bldr.toString();
	'	}
	
	'}
	
	protected static abstract class <className_compactNode(ts, setup, true, true)><Generics(ts.ds, ts.tupleTypes)> extends <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> {

		private <dec(ts.bitmapField)>;
		private <dec(ts.valmapField)>;

		<className_compactNode(ts, setup, true, true)>(final AtomicReference\<Thread\> mutator, <dec(ts.bitmapField)>, <dec(ts.valmapField)>) {
			this.<bitmapField.name> = <bitmapField.name>;
			this.<valmapField.name> = <valmapField.name>;
		}

		@Override
		public <typeToString(ts.bitmapField.\type)> <bitmapField.name>() {
			return <bitmapField.name>;
		}

		@Override
		public <typeToString(ts.valmapField.\type)> <valmapField.name>() {
			return <valmapField.name>;
		}

	}

	<if (isOptionEnabled(setup,useSpecialization())) {>
	protected static abstract class <className_compactNode(ts, setup, true, false)><Generics(ts.ds, ts.tupleTypes)> extends <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> {

		private <dec(ts.bitmapField)>;

		<className_compactNode(ts, setup, true, false)>(final AtomicReference\<Thread\> mutator, <dec(ts.bitmapField)>, <dec(ts.valmapField)>) {
			this.<bitmapField.name> = <bitmapField.name>;
		}

		@Override
		public <typeToString(ts.bitmapField.\type)> <bitmapField.name>() {
			return <bitmapField.name>;
		}

		@Override
		public <typeToString(ts.valmapField.\type)> <valmapField.name>() {
			return 0;
		}

	}

	protected static abstract class <className_compactNode(ts, setup, false, true)><Generics(ts.ds, ts.tupleTypes)> extends <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> {

		private <dec(ts.valmapField)>;

		<className_compactNode(ts, setup, false, true)>(final AtomicReference\<Thread\> mutator, <dec(ts.bitmapField)>, <dec(ts.valmapField)>) {
			this.<valmapField.name> = <valmapField.name>;
		}

		@Override
		public <typeToString(ts.bitmapField.\type)> <bitmapField.name>() {
			return 0;
		}

		@Override
		public <typeToString(ts.valmapField.\type)> <valmapField.name>() {
			return <valmapField.name>;
		}

	}
	
	protected static abstract class <className_compactNode(ts, setup, false, false)><Generics(ts.ds, ts.tupleTypes)> extends <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> {

		<className_compactNode(ts, setup, false, false)>(final AtomicReference\<Thread\> mutator, <dec(ts.bitmapField)>, <dec(ts.valmapField)>) {
		}

		@Override
		public <typeToString(ts.bitmapField.\type)> <bitmapField.name>() {
			return 0;
		}

		@Override
		public <typeToString(ts.valmapField.\type)> <valmapField.name>() {
			return 0;
		}

	}
	<}>
	"
	;
	
}

str generate_bodyOf_mergeTwoValues(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionField()) =
	"if (mask0 \< mask1) {
	'	return nodeOf(null, (byte) mask0, <use(__payloadTuple(ts.ds, ts.tupleTypes, 0))>, (byte) mask1, <use(__payloadTuple(ts.ds, ts.tupleTypes, 1))>);
	'} else {
	'	return nodeOf(null, (byte) mask1, <use(__payloadTuple(ts.ds, ts.tupleTypes, 1))>, (byte) mask0, <use(__payloadTuple(ts.ds, ts.tupleTypes, 0))>);
	'}";

str generate_bodyOf_mergeTwoValues(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionBitmap()) =
	"<dec(ts.valmapField)> = (<toString(chunkSizeToPrimitive(bitPartitionSize))>) (<toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))> | <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask1))))>);
	' 
	'if (mask0 \< mask1) {
	'	return nodeOf(null, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0, <use(valmapField)>, <use(appendToName(nodeTupleArgs(ts), "0") + appendToName(nodeTupleArgs(ts), "1"))>);
	'} else {
	'	return nodeOf(null, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0, <use(valmapField)>, <use(appendToName(nodeTupleArgs(ts), "1") + appendToName(nodeTupleArgs(ts), "0"))>);
	'}";

/*
 *	Both <call> invocatiosn in the body have similar data; only content array differs.
 */	
str generate_bodyOf_mergeTwoValues(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),false>}, Position _) =
	"<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (<toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))> | <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask1))))>);
	'	
	'if (mask0 \< mask1) {
		return <toString(call(ts.nodeOf_BitmapIndexedNode, 
				argsOverride = (ts.mutator: NULL(),								
								ts.bitmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.bitmapField.\type, "0")), 
								ts.valmapField: useExpr(ts.valmapField),
								ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { <use(appendToName(nodeTupleArgs(ts), "0") + appendToName(nodeTupleArgs(ts), "1"))> }"),
								ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "2")),
								ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "0")))))>;
	'} else {
		return <toString(call(ts.nodeOf_BitmapIndexedNode, 
				argsOverride = (ts.mutator: NULL(),								
								ts.bitmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.bitmapField.\type, "0")), 
								ts.valmapField: useExpr(ts.valmapField),
								ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { <use(appendToName(nodeTupleArgs(ts), "1") + appendToName(nodeTupleArgs(ts), "0"))> }"),
								ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "2")),
								ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "0")))))>;	
	'}";	

default str generate_bodyOf_mergeTwoValues(TrieSpecifics _, Option _, Position _) { throw "something went wrong"; }

str generate_bodyOf_mergeOnNextLevel(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionField()) =
	"return nodeOf(null, (byte) mask0, node);";

str generate_bodyOf_mergeOnNextLevel(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionBitmap()) =
	"<dec(ts.bitmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))>;
	'return nodeOf(null, <use(bitmapField)>, (<toString(chunkSizeToPrimitive(bitPartitionSize))>) 0, node);";		
	
str generate_bodyOf_mergeOnNextLevel(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),false>}, Position _) =
	"<dec(ts.bitmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))>;
	'return <toString(call(ts.nodeOf_BitmapIndexedNode, 
		argsOverride = (ts.mutator: NULL(),								
						ts.bitmapField: useExpr(ts.bitmapField),
						ts.valmapField: cast(chunkSizeToPrimitive(ts.bitPartitionSize), constant(ts.valmapField.\type, "0")),						
						ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { <use(\node(ts.ds, ts.tupleTypes))> }"),
						ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "0")),
						ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "1")))))>;";	

default str generate_bodyOf_mergeOnNextLevel(TrieSpecifics _, Option _, Position _) { throw "something went wrong"; }

str generate_bodyOf_mergeNodeAndValue(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionField()) =
	"// store values before node
	'return nodeOf(null, (byte) mask1, <use(__payloadTuple(ts.ds, ts.tupleTypes, 1))>, (byte) mask0, node0);";

str generate_bodyOf_mergeNodeAndValue(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),true>}, Position pos:positionBitmap()) =
	"<dec(ts.bitmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))>;
	'<dec(ts.valmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask1))))>;
	'
	'// store values before node
	'return nodeOf(null, <use(bitmapField)>, <use(valmapField)>, <use(__payloadTuple(ts.ds, ts.tupleTypes, 1))>, node0);";		
	
str generate_bodyOf_mergeNodeAndValue(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, <useSpecialization(),false>}, Position _) =
	"<dec(ts.bitmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask0))))>;
	'<dec(ts.valmapField)> = <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: useExpr(ts.mask1))))>;
	'
	'// store values before node
	'return <toString(call(ts.nodeOf_BitmapIndexedNode, 
		argsOverride = (ts.mutator: NULL(),								
						ts.BitmapIndexedNode_contentArray: exprFromString("new Object[] { <use(__payloadTuple(ts.ds, ts.tupleTypes, 1))>, <use(\node(ts.ds, ts.tupleTypes, 0))> }"),
								ts.BitmapIndexedNode_payloadArity: cast(ts.BitmapIndexedNode_payloadArity.\type, constant(ts.BitmapIndexedNode_payloadArity.\type, "1")),
								ts.BitmapIndexedNode_nodeArity: cast(ts.BitmapIndexedNode_nodeArity.\type, constant(ts.BitmapIndexedNode_nodeArity.\type, "1")))))>;";			

default str generate_bodyOf_mergeNodeAndValue(TrieSpecifics _, Option _, Position _) { throw "something went wrong"; }


str generate_bodyOf_SpecializedBitmapPositionNode_containsKey(_, _, _, rel[Option,bool] setup, str(Argument, Argument) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;	
	
default str generate_bodyOf_SpecializedBitmapPositionNode_containsKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) = 
	"<dec(ts.mask)> = <toString(call(ts.CompactNode_mask))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;
	'
	'final int dataMap = <use(valmapMethod)>;
	'if ((dataMap & bitpos) != 0) {
	'	final int index = index(dataMap, mask, bitpos);
	'	return <eq(key(ts.keyType, "getKey(index)"), key(ts.keyType))>;
	'}
	'
	'final int nodeMap = <use(bitmapMethod)>;
	'if ((nodeMap & bitpos) != 0) {
	'	final int index = index(nodeMap, mask, bitpos);
	'	return getNode(index).containsKey(<keyName>, <keyName>Hash, shift + BIT_PARTITION_SIZE<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>);
	'}
	'
	'return false;"
	;
	
str generate_bodyOf_SpecializedBitmapPositionNode_findByKey(_, _, _, rel[Option,bool] setup, str(Argument, Argument) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;		
	
str generate_bodyOf_SpecializedBitmapPositionNode_findByKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) = 
	"<dec(ts.mask)> = <toString(call(ts.CompactNode_mask))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;

	'if ((<use(valmapMethod)> & bitpos) != 0) { // inplace value
	'	<dec(ts.index)> = dataIndex(bitpos);
	'	if (<eq(key(ts.keyType, "getKey(<use(ts.index)>)"), key(ts.keyType))>) {
	'		<dec(collTupleArg(ts, 1))> = <toString(call(ts.AbstractNode_getValue))>; // AbstractNode__getValueAsCollection 
	'
	'		return Optional.of(<use(collTupleArg(ts, 1))>);
	'	}
	'
	'	return Optional.empty();
	'}
	'
	'if ((<use(bitmapMethod)> & bitpos) != 0) { // node (not value)
	'	final <AbstractNode(ds)><Generics(ts.ds, ts.tupleTypes)> subNode = nodeAt(bitpos);
	'
	'	return subNode.findByKey(key, keyHash, shift + BIT_PARTITION_SIZE<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>);
	'}
	'
	'return Optional.empty();"
when \map() := ds || ds == \vector()
	;
	
str generate_bodyOf_SpecializedBitmapPositionNode_findByKey(int n, int m, ts:___expandedTrieSpecifics(ds:\set(), bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) = 
	"<dec(ts.mask)> = <toString(call(ts.CompactNode_mask))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;

	'if ((<use(valmapMethod)> & bitpos) != 0) { // inplace value
	'	if (<eq(key(ts.keyType, "keyAt(bitpos)"), key(ts.keyType))>) {
	'		<dec(key(ts.keyType, "_key"))> = keyAt(bitpos);

	'		return Optional.of(<use(key(ts.keyType, "_key"))>);
	'	}
	'
	'	return Optional.empty();
	'}
	'
	'if ((<use(bitmapMethod)> & bitpos) != 0) { // node (not value)
	'	final <AbstractNode(ds)><Generics(ts.ds, ts.tupleTypes)> subNode = nodeAt(bitpos);
	'
	'	return subNode.findByKey(key, keyHash, shift + BIT_PARTITION_SIZE<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>);
	'}
	'
	'return Optional.empty();"
	;
	
default str generate_bodyOf_SpecializedBitmapPositionNode_findByKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) { throw "Ahhh"; }		
	
str updatedOn_KeysEqual(TrieSpecifics ts, str(Argument, Argument) eq) = 
	"return this;" 
when \set() := ts.ds;	
	
str updatedOn_KeysEqual(TrieSpecifics ts, str(Argument, Argument) eq) = 
	"<dec(val(ts.valType, "currentVal"))> = getValue(dataIndex);
	'
	'if (<eq(val(ts.valType, "currentVal"), val(ts.valType))>) {
	'	return this;
	'} else {
	'	// update mapping
	'	details.updated(currentVal);
	'	return copyAndSetValue(mutator, bitpos, val);
	'}" 
when \map(multi = false) := ts.ds;

str updatedOn_KeysEqual(TrieSpecifics ts, str(Argument, Argument) eq, TrieSpecifics tsSet = setTrieSpecificsFromRangeOfMap(ts)) = 
	"<dec(nodeTupleArg(ts, 1))> = getValue(dataIndex);
	'
	'final int valHash = <hashCode(val(ts.valType))>;
	'// if(<use(nodeTupleArg(ts, 1))>.<toString(call(tsSet.AbstractNode_containsKey, 
					argsOverride = (key(tsSet.keyType): useExpr(val(ts.valType)), tsSet.keyHash: exprFromString("improve(valHash)"), tsSet.shift: constant(tsSet.shift.\type, "0"))))>) {
	'if(<use(collTupleArg(ts, 1))>.<toString(call(tsSet.Core_containsKey, 
					argsOverride = (tsSet.stdObjectArg: useExpr(val(ts.valType)))))>) {
	'	return this;
	'} else {
	'	// add new mapping
	'	// <dec(appendToName(nodeTupleArg(ts, 1), "New"))> = <use(nodeTupleArg(ts, 1))>.<toString(call(tsSet.AbstractNode_updated, 
					argsOverride = (tsSet.mutator: NULL(), 
						key(tsSet.keyType): useExpr(val(ts.valType)), 
						tsSet.keyHash: exprFromString("improve(valHash)"), 
						tsSet.shift: constant(tsSet.shift.\type, "0"),
						tsSet.details: exprFromString("<tsSet.ResultStr>.unchanged()"))))>;
	'	<dec(appendToName(collTupleArg(ts, 1), "New"))> = <use(collTupleArg(ts, 1))>.<toString(call(tsSet.Core_updated, 
					argsOverride = (key(tsSet.keyType): useExpr(val(ts.valType)))))>;
	'
	'	details.modified();
	'	return copyAndSetValue(mutator, bitpos, <use(appendToName(nodeTupleArg(ts, 1), "New"))>);
	'}" 
when \map(multi = true) := ts.ds;	







default str updatedOn_KeysDifferent(TrieSpecifics ts, str(Argument, Argument) eq) = 
	"<if (\map() := ts.ds) {><dec(val(ts.valType, "currentVal"))> = getValue(dataIndex);<}> final <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> subNodeNew = mergeTwoKeyValPairs(currentKey, <if (\map() := ts.ds) {> currentVal,<}>improve(<hashCode(key(ts.keyType, "currentKey"))>), key, <if (\map() := ts.ds) {> val,<}> keyHash, shift + BIT_PARTITION_SIZE);
	'
	'details.modified();
	'return copyAndMigrateFromInlineToNode(mutator, bitpos, subNodeNew);";	
		
str updatedOn_KeysDifferent(TrieSpecifics ts, str(Argument, Argument) eq, TrieSpecifics tsSet = setTrieSpecificsFromRangeOfMap(ts)) = 
	"final int valHash = <hashCode(val(ts.valType))>;
	'// <dec(nodeTupleArg(ts, 1))> = CompactSetNode.EMPTY_NODE.<toString(call(tsSet.AbstractNode_updated, 
					argsOverride = (tsSet.mutator: NULL(), 
						key(tsSet.keyType): useExpr(val(ts.valType)), 
						tsSet.keyHash: exprFromString("improve(valHash)"), 
						tsSet.shift: constant(tsSet.shift.\type, "0"),
						tsSet.details: exprFromString("<tsSet.ResultStr>.unchanged()"))))>;
	' <dec(collTupleArg(ts, 1))> = <tsSet.coreSpecializedClassName>.setOf(<use(val(ts.valType))>);
	'
	'<dec(replaceName(nodeTupleArg(ts, 1), "currentValNode"))> = getValue(dataIndex);
	'final <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> subNodeNew = mergeTwoKeyValPairs(currentKey, currentValNode, improve(<hashCode(key(ts.keyType, "currentKey"))>), key, <use(collTupleArg(ts, 1))>, keyHash, shift + BIT_PARTITION_SIZE);
	'
	'details.modified();
	'return copyAndMigrateFromInlineToNode(mutator, bitpos, subNodeNew);" 
when \map(multi = true) := ts.ds;






default str updatedOn_NoTuple(TrieSpecifics ts, str(Argument, Argument) eq) = 
	"<use(ts.details)>.modified();
	'return copyAndInsertValue(mutator, bitpos, key<if (\map() := ts.ds) {>, val<}>);";
		
str updatedOn_NoTuple(TrieSpecifics ts, str(Argument, Argument) eq, TrieSpecifics tsSet = setTrieSpecificsFromRangeOfMap(ts)) = 
	"final int valHash = <hashCode(val(ts.valType))>;
	'// <dec(nodeTupleArg(ts, 1))> = CompactSetNode.EMPTY_NODE.<toString(call(tsSet.AbstractNode_updated, 
					argsOverride = (tsSet.mutator: NULL(), 
						key(tsSet.keyType): useExpr(val(ts.valType)), 
						tsSet.keyHash: exprFromString("improve(valHash)"), 
						tsSet.shift: constant(tsSet.shift.\type, "0"),
						tsSet.details: exprFromString("<tsSet.ResultStr>.unchanged()"))))>;
	' <dec(collTupleArg(ts, 1))> = <tsSet.coreSpecializedClassName>.setOf(<use(val(ts.valType))>);
	'
	'details.modified();
	'return copyAndInsertValue(mutator, bitpos, <use(nodeTupleArgs(ts))>);"
when \map(multi = true) := ts.ds;


/*
default str generate_bodyOf_Core_updated(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq) {

	str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>";

	return  
	"	final int keyHash = key.hashCode();
		<dec(ts.details)> = <ts.ResultStr>.unchanged();
		
		<dec(\node(ts.ds, ts.tupleTypes, "newRootNode"))> = rootNode.updated(null, <use(ts.payloadTuple)>, improve(keyHash), 0, <use(ts.details)><optionalComparatorArgument>);

		if (<use(ts.details)>.isModified()) {
			<if (\map() := ts.ds) {>
				if (<use(ts.details)>.hasReplacedValue()) {
					final int valHashOld = <hashCode(val(ts.valType, "<use(ts.details)>.getReplacedValue()"))>;
					final int valHashNew = <hashCode(val(ts.valType))>;
	
					return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + (keyHash ^ valHashNew)
									- (keyHash ^ valHashOld), cachedSize);
				}
			<}>
				
			<if (\map() := ts.ds) {>
				final int valHash = <hashCode(val(ts.valType))>;
				return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + (keyHash ^ valHash), cachedSize + 1);
			<} else {>
				return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + keyHash, cachedSize + 1);			
			<}>
		}

		return this;"
	;
}


default str generate_bodyOf_Core_containsKey(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>") =
	"try {
		<toString(UNCHECKED_ANNOTATION())>
		<dec(key(ts.keyType))> = (<toString(ts.keyType)>) o;
		return rootNode.containsKey(<use(key(ts.keyType))>, improve(<hashCode(key(ts.keyType))>), 0<optionalComparatorArgument>);			
	} catch (ClassCastException unused) {
		return false;
	}"
	;

*/	

str generate_bodyOf_SpecializedBitmapPositionNode_updated(_, _, _, rel[Option,bool] setup, str(Argument, Argument) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;
	
default str generate_bodyOf_SpecializedBitmapPositionNode_updated(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) {
	
	Argument subNode 	= \node(ts.ds, ts.tupleTypes, "subNode");
	Argument subNodeNew = \node(ts.ds, ts.tupleTypes, "subNodeNew");

	return  
	"<dec(ts.mask)> = <toString(call(ts.CompactNode_mask))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;
	'
	'if ((<use(valmapMethod)> & bitpos) != 0) { // inplace value
	'	<dec(field(primitive("int"), "dataIndex"))> = dataIndex(bitpos);
	'	<dec(key(ts.keyType, "currentKey"))> = getKey(dataIndex);
	'
	'	if (<eq(key(ts.keyType, "currentKey"), key(ts.keyType))>) {
	'		<updatedOn_KeysEqual(ts, eq)>				
	'	} else {
	'		<updatedOn_KeysDifferent(ts, eq)>					
	'	}
	'} else if ((<use(bitmapMethod)> & bitpos) != 0) { // node (not value)
	'	<dec(subNode)> = nodeAt(bitpos);
	'	<dec(subNodeNew)> = <use(subNode)>.updated(mutator, <use(ts.payloadTuple)>, keyHash, shift + BIT_PARTITION_SIZE, <use(ts.details)><if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>);
	'
	'	if (<use(ts.details)>.isModified()) {
	'		return copyAndSetNode(mutator, bitpos, <use(subNodeNew)>);
	'	} else {
	'		return this;
	'	}
	'} else {
	'	// no value
	'	<updatedOn_NoTuple(ts, eq)>
	'}"
	;
}
	

default str removedOn_TupleFound(TrieSpecifics ts, str(Argument, Argument) eq) =
	"<if (\map() := ds) {><dec(val(ts.valType, "currentVal"))> = getValue(dataIndex); details.updated(currentVal);<} else {>details.modified();<}>
	
	<removed_value_block1(ts, setup)> else <if (isOptionEnabled(setup,useSpecialization())) {><removed_value_block2(ts, setup)> else<}> {					
		return copyAndRemoveValue(mutator, bitpos);
	}";
	
str removedOn_TupleFound(TrieSpecifics ts, str(Argument, Argument) eq, TrieSpecifics tsSet = setTrieSpecificsFromRangeOfMap(ts)) = 
	"<dec(nodeTupleArg(ts, 1))> = getValue(dataIndex); 
	'
	'final int valHash = <hashCode(val(ts.valType))>;
	'// if(<use(nodeTupleArg(ts, 1))>.<toString(call(tsSet.AbstractNode_containsKey, 
					argsOverride = (key(tsSet.keyType): useExpr(val(ts.valType)), tsSet.keyHash: exprFromString("improve(valHash)"), tsSet.shift: constant(tsSet.shift.\type, "0"))))>) {
	' if(<use(collTupleArg(ts, 1))>.<toString(call(tsSet.Core_containsKey, 
					argsOverride = (tsSet.stdObjectArg: useExpr(val(ts.valType)))))>) {
	'	details.updated(<use(val(ts.valType))>);
	'	
	'	// remove mapping
	'	// <dec(appendToName(nodeTupleArg(ts, 1), "New"))> = <use(nodeTupleArg(ts, 1))>.<toString(call(tsSet.AbstractNode_removed, 
					argsOverride = (tsSet.mutator: NULL(), 
						key(tsSet.keyType): useExpr(val(ts.valType)), 
						tsSet.keyHash: exprFromString("improve(valHash)"), 
						tsSet.shift: constant(tsSet.shift.\type, "0"),
						tsSet.details: exprFromString("<tsSet.ResultStr>.unchanged()"))))>;
	'	<dec(appendToName(nodeTupleArg(ts, 1), "New"))> = <use(nodeTupleArg(ts, 1))>.<toString(call(tsSet.Core_removed, 
					argsOverride = (key(tsSet.keyType): useExpr(val(ts.valType)))))>;
	'	
	'	if (<use(appendToName(nodeTupleArg(ts, 1), "New"))>.size() == 0) { // earlier: arity() == 0
	'		<removed_value_block1(ts, ts.setup)> else <if (isOptionEnabled(ts.setup,useSpecialization())) {><removed_value_block2(ts, ts.setup)> else<}> {					
	'			return copyAndRemoveValue(mutator, bitpos);
	'		}
	'	} else {
	'		return copyAndSetValue(mutator, bitpos, <use(appendToName(nodeTupleArg(ts, 1), "New"))>);		
	'	}	
	'} else {	
	'	return this;
	'}" 
when \map(multi = true) := ts.ds;
	
str generate_bodyOf_SpecializedBitmapPositionNode_removed(_, _, _, rel[Option,bool] setup, str(Argument, Argument) eq, Method nodeRemovedMethod)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;			
		
default str generate_bodyOf_SpecializedBitmapPositionNode_removed(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq, Method nodeRemovedMethod) {

	Argument subNode 	= \node(ts.ds, ts.tupleTypes, "subNode");
	Argument subNodeNew = \node(ts.ds, ts.tupleTypes, "subNodeNew");

	return
	"<dec(ts.mask)> = <toString(call(ts.CompactNode_mask))>;
	<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;

	if ((<use(valmapMethod)> & bitpos) != 0) { // inplace value
		<dec(field(primitive("int"), "dataIndex"))> = dataIndex(bitpos);
		
		if (<eq(key(ts.keyType, "getKey(dataIndex)"), key(ts.keyType))>) {
			<removedOn_TupleFound(ts, eq)>
		} else {		
			return this;
		}
	} else if ((<use(bitmapMethod)> & bitpos) != 0) { // node (not value)
		<dec(subNode)> = nodeAt(bitpos);
		<dec(subNodeNew)> = subNode.<toString(call(nodeRemovedMethod, argsOverride = (ts.shift: exprFromString("shift + BIT_PARTITION_SIZE"))))>;

		if (!<use(ts.details)>.isModified()) {
			return this;
		}
		
		switch (subNodeNew.sizePredicate()) {
		case 0: {
			throw new IllegalStateException(\"Sub-node must have at least one element.\"); 
		}
		case 1: {
			<if (isOptionEnabled(setup,useSpecialization())) {>// inline value (move to front)
				details.modified();
				return copyAndMigrateFromNodeToInline(mutator, bitpos, subNodeNew);<} else {>if (this.payloadArity() == 0 && this.nodeArity() == 1) {
				// escalate (singleton or empty) result
				return <use(subNodeNew)>;
			} else {
				// inline value (move to front)
				return copyAndMigrateFromNodeToInline(mutator, bitpos, subNodeNew);
			}<}>
		}
		default: {
			// modify current node (set replacement node)
			return copyAndSetNode(mutator, bitpos, subNodeNew);
		}
		}		
	}

	return this;";
}
	
default str removed_value_block2(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) =
	"if (this.arity() == <nBound + 1>) {
	'	return removeInplaceValueAndConvertToSpecializedNode(mutator, bitpos);
	'}";
	
default str removed_value_block1(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) =
	"if (this.payloadArity() == 2 && this.nodeArity() == 0) {
	'	/*
	'	 * Create new node with remaining pair. The new node
	'	 * will a) either become the new root returned, or b)
	'	 * unwrapped and inlined during returning.
	'	 */
	'	final <typeToString(chunkSizeToPrimitive(bitPartitionSize))> newDataMap = (shift == 0) ? (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (<use(valmapMethod)> ^ bitpos)
	'					: <toString(call(ts.CompactNode_bitpos, argsOverride = (ts.mask: call(ts.CompactNode_mask, argsOverride = (ts.shift: constant(primitive("int"), "0"))))))>;
	'
	'	if (dataIndex == 0) {
	'		return <CompactNode(ts.ds)>.<Generics(ts.ds, ts.tupleTypes)> nodeOf(mutator, (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) 0,
	'						newDataMap, getKey(1)<if (\map() := ds) {>, getValue(1)<}>);
	'	} else {
	'		return <CompactNode(ts.ds)>.<Generics(ts.ds, ts.tupleTypes)> nodeOf(mutator, (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) 0,
	'						newDataMap, getKey(0)<if (\map() := ds) {>, getValue(0)<}>);
	'	}
	'}";
	
	
// bit-shifting with signed integers in Java
int oneShiftedLeftBy(int count) = toInt(pow(2, count)) when count >= 0 && count <= 30;
int oneShiftedLeftBy(31) = -2147483648;
default int oneShiftedLeftBy(int count) { throw "Not supported!"; }


Method CompactNode_factoryMethod_bitmap(int n, int m, TrieSpecifics ts) {
	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, ts.setup);

	return function(ts.compactNodeClassReturn, "nodeOf", generics = "<Generics(ts.ds, ts.tupleTypes)>", args = constructorArgs);	
}

str generate_bodyOf_factoryMethod_bitmap(int n:0, int m:0, TrieSpecifics ts, Method decleration) { 
	return "return <emptyTrieNodeConstantName>;";
}

//str generate_valNodeOf_factoryMethod_bitmap(n:1, m:0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, compactionViaFieldToMethod()}) {
//	// TODO: remove code duplication
//	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, setup);
//
//	specializedClassName = "<toString(ds)><m>To<n>Node<ts.classNamePostfix>";
//
//	return
//	"static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
//	'	switch(<use(bitmapMethod)>) {
//	'	<for (i <- [1..nMax+1]) {>case <oneShiftedLeftBy(i-1)>:
//	'		return new <toString(ds)><m>To<n>NodeAtMask<i-1><InferredGenerics(ts.ds, ts.tupleTypes)>(<intercalate(", ", mapper(constructorArgs, use))>);
//	'	<}>default:
//	'		throw new IllegalStateException(\"Index out of range.\");
//	'	}
//	'}"
//	;
//}

str generate_bodyOf_factoryMethod_bitmap(int n, int m, TrieSpecifics ts, Method decleration) 
	= "return new <specializedClassName(n, m, ts)><InferredGenerics(ts.ds, ts.tupleTypes)>(<use(decleration.args)>);"
when (n + m) <= ts.nBound
	;

/* TODO: fix argument lists! */
str generate_bodyOf_factoryMethod_bitmap(int n, int m, TrieSpecifics ts, Method decleration) {
	if (!((n + m) == ts.nBound + 1 && (n + m) < ts.nMax)) {
		fail;
	}

	list[Argument] argsForArray = contentArguments(n, m, ts, ts.setup);

	return "return nodeOf(mutator, <bitmapField.name>, <valmapField.name>, new Object[] { <use(argsForArray)> }<if (!isOptionEnabled(ts.setup,useSandwichArrays())) {>, (byte) <m><}>);";
}

default str generate_bodyOf_factoryMethod_bitmap(int n, int m, TrieSpecifics ts, Method decleration) { 
	throw "Arguments out of bounds (n = <n>, m = <m>)."; 
}


str generate_valNodeOf_factoryMethod_bitmap_untyped(mn:0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int n = 0, int m = 0) { 
	// TODO: remove code duplication
	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, setup);

	return
	"static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
	'	return <emptyTrieNodeConstantName>;
	'}"
	;
}

//str generate_valNodeOf_factoryMethod_bitmap_untyped(n:1, m:0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup:{_*, compactionViaFieldToMethod()}) {
//	// TODO: remove code duplication
//	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, setup);
//
//	specializedClassName = "<toString(ds)><m>To<n>Node<ts.classNamePostfix>";
//
//	return
//	"static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
//	'	switch(<use(bitmapMethod)>) {
//	'	<for (i <- [1..nMax+1]) {>case <oneShiftedLeftBy(i-1)>:
//	'		return new <toString(ds)><m>To<n>NodeAtMask<i-1><InferredGenerics(ts.ds, ts.tupleTypes)>(<intercalate(", ", mapper(constructorArgs, use))>);
//	'	<}>default:
//	'		throw new IllegalStateException(\"Index out of range.\");
//	'	}
//	'}"
//	;
//}

default str generate_valNodeOf_factoryMethod_bitmap_untyped(int mn, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int n = mn, int m = 0) {
	// TODO: remove code duplication
	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, setup);

	if ((mn) <= tupleLength(ds) * nBound) {		
		return
		"static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
		'	return new <specializedClassName(n, m, ts)><InferredGenerics(ts.ds, ts.tupleTypes)>(<intercalate(", ", mapper(constructorArgs, use))>);
		'}
		"; 
	} else if ((mn) > tupleLength(ds) * nBound && (mn) <= tupleLength(ds) * nBound + tupleLength(ds) && (mn) < tupleLength(ds) * nMax) {
		list[Argument] argsForArray = contentArguments(n, m, ts, setup);

		return
		"static final <Generics(ts.ds, ts.tupleTypes)> <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
		'	return nodeOf(mutator, <bitmapField.name>, <valmapField.name>, new Object[] { <use(argsForArray)> }<if (!isOptionEnabled(ts.setup,useSandwichArrays())) {>, (byte) <integerOrLongObject(bitPartitionSize)>.bitCount(<useSafeUnsigned(ts.valmapField)>)<}>);
		'}
		";
	} else {
		throw "Arguments out of bounds (n = <n>, m = <m>).";
	}
}



// 		<generate_valNodeOf_factoryMethod_bitmap(i, j, ts, setup)>
str generate_specializationFactoryMethods(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 
	//  && !(i == nBound + 1)

	"
	<for(j <- [0..nMax+1], i <- [0..nMax+1], ((i + j) <= nMax && (i + j) <= nBound + 1)) {>
		<implOrOverride(CompactNode_factoryMethod_bitmap(i, j, ts), generate_bodyOf_factoryMethod_bitmap(i, j, ts, CompactNode_factoryMethod_bitmap(i, j, ts)))>
	<}>
	"
when isOptionEnabled(setup,useSpecialization()) && !isOptionEnabled(setup,useUntypedVariables())
	;
	
/**
 * More complicated slot count expression.
 * sort(toList({ n + 2 * m | n <- [0..32+1], m <- [0..32+1], ((n + m) <= 32)}))
 */
str generate_specializationFactoryMethods(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 
	"
	<for(mn <- [0.. tupleLength(ds) * nMax + 1], mn <= tupleLength(ds) * nBound + tupleLength(ds)) {>
		<generate_valNodeOf_factoryMethod_bitmap_untyped(mn, ts, setup)>
	<}>
	"
when isOptionEnabled(setup,useSpecialization()) && isOptionEnabled(setup,useUntypedVariables())
	;
		
default str generate_specializationFactoryMethods(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = "";





list[Argument] invoke_get_for_payloadTuple(DataStructure ds:\map(), list[Type] tupleTypes:[keyType, valType, *_], Argument idx) = [ key(keyType, "getKey(<use(idx)>)"), val(valType, "getValue(<use(idx)>)") ];
list[Argument] invoke_get_for_payloadTuple(DataStructure ds:\set(), list[Type] tupleTypes:[keyType, *_], Argument idx) = [ key(keyType, "getKey(<use(idx)>)") ];





str generate_bodyOf_mask(TrieSpecifics ts, Method decleration) =
	// "return (<use(ts.keyHash)> \>\>\> (Math.max(0, <32 - ts.bitPartitionSize> - <use(ts.shift)>))) & BIT_PARTITION_MASK;"
	
	"if (<use(ts.shift)> == 30) {
	'	return keyHash & BIT_PARTITION_MASK;
	'} else {
	'	return (<use(ts.keyHash)> \>\>\> (<32 - ts.bitPartitionSize> - <use(ts.shift)>)) & BIT_PARTITION_MASK;
	'}"
when isOptionEnabled(ts.setup, usePrefixInsteadOfPostfixEncoding());

default str generate_bodyOf_mask(TrieSpecifics ts, Method decleration) =
	"return (<use(ts.keyHash)> \>\>\> <use(ts.shift)>) & BIT_PARTITION_MASK;";
	
default str generate_bodyOf_bitpos(TrieSpecifics ts, Method decleration) =
	"return (<typeToString(chunkSizeToPrimitive(ts.bitPartitionSize))>) (1L \<\< <use(ts.mask)>);";	
	
	
default str generate_bodyOf_mergeTwoKeyValPairs(TrieSpecifics ts) = 
	"assert !(<equalityDefaultForArguments(key(ts.keyType, "key0"), key(ts.keyType, "key1"))>);
	
	if (<use(ts.shift)> \>= HASH_CODE_LENGTH) {
		throw new IllegalStateException(\"Hash collision not yet fixed.\");
		//return new <ts.hashCollisionClassName><InferredGenerics(ts.ds, ts.tupleTypes)>(keyHash0, (<typeToString(nodeTupleType(ts, 0))>[]) new <if (isPrimitive(nodeTupleArg(ts, 0))) {><toString(nodeTupleType(ts, 0))><} else {>Object<}>[] { <use(appendToName([ "0", "1" ], nodeTupleArg(ts, 0)))> }
		//				<if (\map() := ts.ds) {>, (<typeToString(nodeTupleType(ts, 1))>[]) new <if (isPrimitive(nodeTupleArg(ts, 1))) {><toString(nodeTupleType(ts, 1))><} else {>Object<}>[] { <use(appendToName([ "0", "1" ], nodeTupleArg(ts, 1)))> }<}>);
	}

	<dec(ts.mask0)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
	<dec(ts.mask1)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;

	if (mask0 != mask1) {
		// both nodes fit on same level
		<generate_bodyOf_mergeTwoValues(ts, ts.setup, positionBitmap())>
	} else {
		final <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> node = <toString(call(ts.CompactNode_mergeTwoKeyValPairs, argsOverride = (ts.shift: plus(useExpr(ts.shift), useExpr(ts.BIT_PARTITION_SIZE)))))>;
		// values fit on next level

		<generate_bodyOf_mergeOnNextLevel(ts, ts.setup, positionBitmap())>
	}";	
	
str generate_bodyOf_mergeTwoKeyValPairs(TrieSpecifics ts) = 
	"assert !(<equalityDefaultForArguments(key(ts.keyType, "key0"), key(ts.keyType, "key1"))>);

	if (keyHash0 == keyHash1) {
		return new <ts.hashCollisionClassName><InferredGenerics(ts.ds, ts.tupleTypes)>(keyHash0, (<toString(ts.keyType)>[]) new <if (isPrimitive(ts.keyType)) {><toString(ts.keyType)><} else {>Object<}>[] { key0, key1 }
						<if (\map() := ts.ds) {>, (<toString(ts.valType)>[]) new <if (isPrimitive(ts.valType)) {><toString(ts.valType)><} else {>Object<}>[] { val0, val1 }<}>);
	}

	int originalShift = shift;

	<dec(ts.mask0)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
	<dec(ts.mask1)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;

	while (mask0 == mask1) {
		shift += BIT_PARTITION_SIZE;

		mask0 = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
		mask1 = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;
	}

	final int dataMap = bitpos(mask0) | bitpos(mask1);
	final Object[] content;
	
	if (mask0 \< mask1) {
		content = new Object[] { <use([ *__payloadTuple(ts.ds, ts.tupleTypes, 0), *__payloadTuple(ts.ds, ts.tupleTypes, 1) ])> };
	} else {
		content = new Object[] { <use([ *__payloadTuple(ts.ds, ts.tupleTypes, 1), *__payloadTuple(ts.ds, ts.tupleTypes, 0) ])> };
	}
			
	// TODO: old semantics; fixme, I am still wrong
	if (shift != originalShift) {
		// apply path compression (TODO: correct allocation)
		return new PathCompressedBitmapIndexedMapNode_ValuesOnly\<\>(null, dataMap, content, shift, prefix(keyHash0, shift));
	} else {
		// path compression not necessary (TODO: correct allocation)
		return new BitmapIndexedMapNode_ValuesOnly\<\>(null, dataMap, content);
	}"
when isOptionEnabled(ts.setup, usePathCompression());
	
	
default str generate_bodyOf_mergeNodeAndKeyValPair(TrieSpecifics ts) = 
	"<dec(ts.mask0)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
	<dec(ts.mask1)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;

	if (mask0 != mask1) {
		// both nodes fit on same level
		<generate_bodyOf_mergeNodeAndValue(ts, ts.setup, positionBitmap())>
	} else {
		// values fit on next level
		final <CompactNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> node = <toString(call(ts.CompactNode_mergeNodeAndKeyValPair, argsOverride = (ts.shift: plus(useExpr(ts.shift), useExpr(ts.BIT_PARTITION_SIZE)))))>;
		
		<generate_bodyOf_mergeOnNextLevel(ts, ts.setup, positionBitmap())>
	}";	

str generate_bodyOf_mergeNodeAndKeyValPair(TrieSpecifics ts) = 
	"if (keyHash0 == keyHash1) {
		return new <ts.hashCollisionClassName><InferredGenerics(ts.ds, ts.tupleTypes)>(keyHash0, (<toString(ts.keyType)>[]) new <if (isPrimitive(ts.keyType)) {><toString(ts.keyType)><} else {>Object<}>[] { key0, key1 }
						<if (\map() := ts.ds) {>, (<toString(ts.valType)>[]) new <if (isPrimitive(ts.valType)) {><toString(ts.valType)><} else {>Object<}>[] { val0, val1 }<}>);
	}

	int originalShift = shift;

	<dec(ts.mask0)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
	<dec(ts.mask1)> = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;

	while (mask0 == mask1) {
		shift += BIT_PARTITION_SIZE;

		mask0 = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash0))))>;
		mask1 = <toString(call(ts.CompactNode_mask, argsOverride = (ts.keyHash: useExpr(ts.keyHash1))))>;
	}
	
	// both nodes fit on same level
	final int nodeMap = bitpos(mask0);
	final int dataMap = bitpos(mask1);

	// store values before node
	final Object[] content = new Object[] { key1, val1, node0 };
	
	// TODO: old semantics; fixme, I am still wrong
	if (shift != originalShift) {
		// apply path compression (TODO: correct allocation)
		return new PathCompressedBitmapIndexedMapNode_Mixed\<\>(null, nodeMap, dataMap,
						content, shift, prefix(keyHash0, shift));

	} else {
		// path compression not necessary (TODO: correct allocation)
		return new BitmapIndexedMapNode_Mixed\<\>(null, nodeMap, dataMap, content);
	}"
when isOptionEnabled(ts.setup, usePathCompression());
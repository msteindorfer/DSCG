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
module dscg::GenerateTrie

import IO;
import List;
import String;
import util::Math;

import dscg::GenerateTrie_Master;

data TrieConfig 
	= hashTrieConfig(DataStructure ds, int bitPartitionSize, list[Type] tupleTypes, SpecializationConfig specializationConfig);

data SpecializationConfig 
	= withoutSpecialization()
	| specializationConfig(int specializeTo, bool flagUntypedVariables);

void main() {
	dataStructures = { \set(), \map() };
	bitPartitionSizes = { 5 };
	typeCombGenInt = { generic("K"), primitive("int") } * { primitive("int"), generic("V") };
	
	specializeToBounds = { 8 };
	booleanOptions = { true, false };
				
	set[SpecializationConfig] specializationConfigs 
		= { specializationConfig(specializeTo, flagUntypedVariables) | 
				<int specializeTo, bool flagUntypedVariables> <- specializeToBounds * booleanOptions } 
		+ withoutSpecialization();
			
	set[TrieConfig] trieConfigs 
		= { hashTrieConfig(d,b,[keyType,valType],s) | 
				d <- dataStructures, b <- bitPartitionSizes, t:<keyType,valType> <- typeCombGenInt, s <- specializationConfigs,
					(specializationConfig(_,true) := s) ==> (isGeneric(keyType) && isGeneric(valType)),
					(withoutSpecialization() := s) ==> (isGeneric(keyType) && isGeneric(valType))};					
				
	for (TrieConfig cfg <- trieConfigs) {
		doGenerate(cfg);
	}
	
	doGenerateInterfaces();	
}

void doGenerateInterfaces() {
	TrieSpecifics genericTsSet = expandConfigurationAndCreateModel(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], withoutSpecialization()), "");
	TrieSpecifics genericTsMap = expandConfigurationAndCreateModel(hashTrieConfig(\map(), 5, [generic("K"), generic("V")], withoutSpecialization()), "");
	
	writeFile(|project://<targetProject>/<targetFolder>/<immutableInterfaceName(\set())>.java|, generateImmutableInterface(genericTsSet));
	writeFile(|project://<targetProject>/<targetFolder>/<transientInterfaceName(\set())>.java|, generateTransientInterface(genericTsSet));

	writeFile(|project://<targetProject>/<targetFolder>/<immutableInterfaceName(\map())>.java|, generateImmutableInterface(genericTsMap));
	writeFile(|project://<targetProject>/<targetFolder>/<transientInterfaceName(\map())>.java|, generateTransientInterface(genericTsMap));	
}

void doGenerateCurrent() {
	doGenerate(hashTrieConfig(\map(), 5, [generic("K"), generic("V")], withoutSpecialization()));
	doGenerate(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], withoutSpecialization()));	
}

void doGenerateBleedingEdge() {
	// generate map and set interfaces
	doGenerateInterfaces();

	TrieConfig tcMultimap = hashTrieConfig(\map(multi = true), 5, [generic("K"), generic("V")], withoutSpecialization());

	writeFile(|project://<targetProject>/<targetFolder>/<immutableInterfaceName(\map(multi = true))>.java|, generateImmutableInterface(expandConfigurationAndCreateModel(tcMultimap, "")));
	writeFile(|project://<targetProject>/<targetFolder>/<transientInterfaceName(\map(multi = true))>.java|, generateTransientInterface(expandConfigurationAndCreateModel(tcMultimap, "")));

	doGenerate(tcMultimap, overideClassNamePostfixWith = "BleedingEdge");
	
	doGenerate(hashTrieConfig(\map(), 5, [generic("K"), generic("V")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");
	doGenerate(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");	

	//doGenerate(hashTrieConfig(\map(), 5, [primitive("int"), primitive("int")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");
	//doGenerate(hashTrieConfig(\set(), 5, [primitive("int"), primitive("int")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");	

	//doGenerate(hashTrieConfig(\map(), 5, [generic("K"), generic("V")], specializationConfig(1, false)), overideClassNamePostfixWith = "BleedingEdge");
	//doGenerate(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], specializationConfig(1, false)), overideClassNamePostfixWith = "BleedingEdge");	
}

void doGenerateBleedingEdgeMultimap() {
	doGenerate(hashTrieConfig(\map(multi = true), 5, [generic("K"), generic("V")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");
	//doGenerate(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], withoutSpecialization()), overideClassNamePostfixWith = "BleedingEdge");	
}

void doGenerateSpecializedUntyped() {
	doGenerate(hashTrieConfig(\map(), 5, [generic("K"), generic("V")], specializationConfig(8, true)));
	doGenerate(hashTrieConfig(\set(), 5, [generic("K"), generic("V")], specializationConfig(8, true)));	
}

TrieSpecifics expandConfigurationAndCreateModel(TrieConfig cfg, str overideClassNamePostfixWith) {
	TrieSpecifics ts = expandConfiguration(cfg, overideClassNamePostfixWith);
	
	// *** STAGE: CREATE MODEL *** //
	return ts[model = buildLanguageAgnosticModel(ts)];	
}

TrieSpecifics expandConfiguration(TrieConfig cfg:hashTrieConfig(DataStructure ds, int bitPartitionSize, list[Type] tupleTypes:[keyType, valType, *_], SpecializationConfig specializationConfig), str overideClassNamePostfixWith) {
	bool flagSpecialization = false;
	int specializeTo = 0;
	bool flagUntypedVariables = false;	

	if (specializationConfig(__specializeTo, __flagUntypedVariables) := specializationConfig) {
		flagSpecialization = true;
		specializeTo = __specializeTo;
		flagUntypedVariables = __flagUntypedVariables;
	}
		
	str classNamePostfix = "_<bitPartitionSize>Bits";
	
	if (flagUntypedVariables) {
		classNamePostfix = classNamePostfix + "_Untyped";
	}
	
	if (flagSpecialization) {
		classNamePostfix = classNamePostfix + "_Spec0To<specializeTo>";
	}	
	
	if (!isGeneric(keyType)) {
		classNamePostfix = classNamePostfix + "_<capitalize(typeToString(keyType))>Key";
	}	
	if (!isGeneric(valType) && \map() := ds) {
		classNamePostfix = classNamePostfix + "_<capitalize(typeToString(valType))>Value";
	}

	if (overideClassNamePostfixWith != "") {
		classNamePostfix = "_<overideClassNamePostfixWith>";
	}

	rel[Option,bool] setup = { 
		<useSpecialization(),flagSpecialization>,
		<useUntypedVariables(),flagUntypedVariables>,
		<useFixedStackIterator(),true>,
		<useSupplierIterator(),false>,
		<useStructuralEquality(),true>,
		<methodsWithComparator(),true>,
		<useSandwichArrays(),true>,
		<useStagedMutability(),true>,
		<usePrefixInsteadOfPostfixEncoding(),false>,	
		<usePathCompression(),false>,
		<useIncrementalHashCodes(),true>,
		<separateTrieAndLeafNodes(),false>
	}; // { compactionViaFieldToMethod() };

	return trieSpecifics(ds, bitPartitionSize, specializeTo, keyType, valType, classNamePostfix, setup, unknownArtifact());
}

void doGenerate(TrieConfig cfg, str overideClassNamePostfixWith = "") {
	TrieSpecifics ts = expandConfiguration(cfg, overideClassNamePostfixWith);
	
	// *** STAGE: CREATE MODEL *** //
	ts = ts[model = buildLanguageAgnosticModel(ts)];
	
	// *** STAGE: GENERATE CODE *** //
	
	list[str] innerClassStrings = doGenerateInnerClassStrings(ts);
	//if (\map(multi = true) := ts.ds) {
	//	TrieSpecifics tsSet = setTrieSpecificsFromRangeOfMap(ts);
	//	
	//	innerClassStrings = innerClassStrings
	//	+ [ generateResultClassString(tsSet, ts.setup) ]
	//	+ [ generateAbstractNodeClassString(tsSet)]		
	//	+ [ generateCompactNodeClassString(tsSet, ts.setup)];
	//}	
		
	list[str] classStrings = [ generateCoreClassString(ts, ts.setup, intercalate("\n", innerClassStrings))];			
		
	// writeFile(|project://DSCG/gen/org/eclipse/imp/pdb/facts/util/AbstractSpecialisedTrieMap.java|, classStrings);

	writeFile(|project://<targetProject>/<targetFolder>/Trie<toString(ts.ds)><ts.classNamePostfix>.java|, classStrings);
}
	
list[str] doGenerateInnerClassStrings(TrieSpecifics ts) {
	bool isLegacy = false;

	list[str] innerClassStrings 
		= [ generateOptionalClassString() ]
		+ [ generateResultClassString(ts, ts.setup) ]
		+ [ generateAbstractAnyNodeClassString(ts, ts.setup)]
		+ [ generateAbstractNodeClassString(ts, isLegacy = isLegacy)]
		+ [ generateCompactNodeClassString(ts, isLegacy = isLegacy)];

	if (isOptionEnabled(ts.setup, separateTrieAndLeafNodes())) {
		innerClassStrings = innerClassStrings + [ generateLeafNodeClassString(ts)];
	}

	if (!isOptionEnabled(ts.setup, useSpecialization()) || ts.nBound < ts.nMax) {
		innerClassStrings = innerClassStrings + [ generateBitmapIndexedNodeClassString(ts, isLegacy = isLegacy)];
	}

	innerClassStrings 
		= innerClassStrings
		+ [ generateHashCollisionNodeClassString(ts, isLegacy = isLegacy)]
		+ [ generateIteratorClassString(ts, ts.setup)] // , classNamePostfix
		;
	
	if (!isOptionEnabled(ts.setup, useFixedStackIterator())) {
		innerClassStrings = innerClassStrings + [ generateEasyIteratorClassString(ts, ts.setup)];
	}
	
	innerClassStrings 
		= innerClassStrings
		+ [ generateNodeIteratorClassString(ts, ts.setup, ts.classNamePostfix)]		
		;
		
	if (isOptionEnabled(ts.setup, useStagedMutability())) { 
		innerClassStrings = innerClassStrings + [ generateCoreTransientClassString(ts)];
	}	
		
	if (isOptionEnabled(ts.setup, useSpecialization()) && !isOptionEnabled(ts.setup, useUntypedVariables())) {
		innerClassStrings = innerClassStrings + 
		[ generateSpecializedNodeWithBitmapPositionsClassString(n, m, ts, ts.setup, ts.classNamePostfix) | m <- [0..ts.nMax+1], n <- [0..ts.nMax+1], (n + m) <= ts.nBound ];
	}

	// TODO: fix correct creation of mn instead of m and n		
	if (isOptionEnabled(ts.setup, useSpecialization()) && isOptionEnabled(ts.setup, useUntypedVariables())) {
		innerClassStrings = innerClassStrings + 
		[ generateSpecializedNodeWithBitmapPositionsClassString(mn, 0, ts, ts.setup, ts.classNamePostfix) | mn <- [0.. tupleLength(ts.ds) * ts.nMax + 1], mn <= tupleLength(ts.ds) * ts.nBound ];
	}
	
	return innerClassStrings;
}
	
str generateClassString(int n) =  
	"class Map<n><GenericsStr(ts.tupleTypes)> extends AbstractSpecialisedImmutableMap<GenericsStr(ts.tupleTypes)> {
	'	<for (i <- [1..n+1]) {>
	'	private final K <keyName><i>;
	'	private final V <valName><i>;
	'	<}>	
	'
	'	Map<n>(<for (i <- [1..n+1]) {>final K <keyName><i>, final V <valName><i><if (i != n) {>, <}><}>) {					
	'		<checkForDuplicateKeys(n)><intercalate("\n\n", ["this.<keyName><i> = <keyName><i>; this.<valName><i> = <valName><i>;" | i <- [1..n+1]])>
	'	}

	'	@Override
	'	public boolean <containsKeyMethodName(ds)>(Object <keyName>) {
	'		<generate_bodyOf_containsKeyOrVal(n, equalityDefault, keyName)>	
	'	}

	'	@Override
	'	public boolean <containsKeyMethodName(ds)>Equivalent(Object <keyName>, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_containsKeyOrVal(n, equalityComparator, keyName)>	
	'	}
	
	'	@Override
	'	public boolean containsValue(Object <valName>) { 
	'		<generate_bodyOf_containsKeyOrVal(n, equalityDefault, valName)>
	'	}
	
	'	@Override
	'	public boolean containsValueEquivalent(Object <valName>, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_containsKeyOrVal(n, equalityComparator, valName)>
	'	}
		
	'	@Override
	'	public V get(Object <keyName>) {
	'		<generate_bodyOf_get(n, equalityDefault)>
	'	}
	
	'	@Override
	'	public V getEquivalent(Object <keyName>, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_get(n, equalityComparator)>
	'	}	

	'	@Override
	'	public int size() {
	'		return <n>;
	'	}

	'	@Override
	'	public Set\<Entry<GenericsStr(ts.tupleTypes)>\> entrySet() {
	'		<generate_bodyOf_entrySet(n)>
	'	}

	'	@Override
	'	public Set\<K\> keySet() {
	'		<generate_bodyOf_keySet(n)>
	'	}

	'	@Override
	'	public Collection\<V\> values() {
	'		<generate_bodyOf_values(n)>
	'	}
	
	'	@Override
	'	public SupplierIterator<SupplierIteratorGenerics(ds)> keyIterator() {
	'		<generate_bodyOf_keyIterator(n)>
	'	}	

	'	@Override
	'	public ImmutableMap<GenericsStr(ts.tupleTypes)> __put(K <keyName>, V <valName>) {
	'		<generate_bodyOf_put(n, equalityDefault)>
	'	}
	
	'	@Override
	'	public ImmutableMap<GenericsStr(ts.tupleTypes)> __putEquivalent(K <keyName>, V <valName>, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_put(n, equalityComparator)>
	'	}	

	'	@Override
	'	public ImmutableMap<GenericsStr(ts.tupleTypes)> __remove(K <keyName>) {
	'		<generate_bodyOf_remove(n, equalityDefault)>	
	'	}

	'	@Override
	'	public ImmutableMap<GenericsStr(ts.tupleTypes)> __removeEquivalent(K <keyName>, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_remove(n, equalityComparator)>
	'	}
	
	'	@Override
	'	public TransientMap<GenericsStr(ts.tupleTypes)> asTransient() {
	'		return TrieMap.transientOf(<for (i <- [1..n+1]) {><keyName><i>, <valName><i><if (i != n) {>, <}><}>);
	'	}
	
	'	@Override
	'	public int hashCode() {
	'		<if (n == 0) {>return 0;<} else {>return (<for (i <- [1..n+1]) {>(Objects.hashCode(<keyName><i>) ^ Objects.hashCode(<valName><i>))<if (i != n) {> + <}><}>);<}>
	'	}		
	
	'	@Override
	'	public String toString() {
	'		<if (n == 0) {>return \"{}\";<} else {>return String.format(\"{<for (i <- [1..n+1]) {>%s=%s<if (i != n) {>, <}><}>}\", <for (i <- [1..n+1]) {><keyName><i>, <valName><i><if (i != n) {>, <}><}>);<}>
	'	}
	
	'}
	";
			
// TODO: move to List.rsc?
list[&T] replace(list[&T] xs, list[&T] old, list[&T] new) 
	= before + new + after
when [*before, *old, *after] := xs;
	
default list[&T] replace(list[&T] xs, list[&T] old, list[&T] new) {throw "aaahh";}	

//default list[&T] replace(list[&T] xs, list[&T] old, list[&T] new) = xs;

// TODO: move to List.rsc?
list[&T] insertBeforeOrDefaultAtEnd(list[&T] xs, list[&T] old, list[&T] new)
	= before + new + old + after
when [*before, *old, *after] := xs;	

default list[&T] insertBeforeOrDefaultAtEnd(list[&T] xs, list[&T] old, list[&T] new) = xs + new;		

// TODO: move to List.rsc?
list[&T] insertAfterOrDefaultAtFront(list[&T] xs, list[&T] old, list[&T] new)
	= before + old + new + after
when [*before, *old, *after] := xs;	

default list[&T] insertAfterOrDefaultAtFront(list[&T] xs, list[&T] old, list[&T] new) = new + xs;

bool exists_bodyOf_updated(0, 0, str(str, str) eq)  = true;
str generate_bodyOf_updated(0, 0, str(str, str) eq) = 
	"final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);
	'return <ts.ResultStr>.modified(<nodeOf(0, 1, "mask, <keyName><if (\map() := ts.ds) {>, <valName><}>")>);"
	;
	
bool exists_bodyOf_updated(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_updated(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;	

default bool exists_bodyOf_updated(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_updated(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq) {	
	// TODO merge both functions
	replaceValueByNode = str (int i, int j) {	
		args = generateMembers(n, m) - payloadTriple(i);
		args = replace(args, subnodePair(j), [field("mask"), field("node")] + subnodePair(j));
		
		return use(args);
	};
	
	// TODO merge both functions
	replaceValueByNodeAtEnd = str (int i) {
		return use(generateMembers(n, m) - payloadTriple(i) + [field("mask"), field("node")]);
	};	
		
	updated_clause_inline = str (int i) { 
		switch (ds) {		
			case \map():
				return 
					"if (mask == <keyPosName><i>) {
					'	if (<eq("<keyName>", "<keyName><i>")>) {
					'		if (<eq("<valName>", "<valName><i>")>) {
					'			result = <ts.ResultStr>.unchanged(this);
					'		} else {		
					'			// update <keyName><i>, <valName><i>
					'			result = <ts.ResultStr>.updated(<nodeOf(n, m, use(replace(generateMembers(n, m), [ val(ts.valType, i) ], [ field(valName) ])))>, <use(val(ts.valType, i))>);
					'		}
					'	} else {
					'		// merge into node
					'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> node = mergeNodes(<keyName><i>, <keyName><i>.hashCode(), <valName><i>, <keyName>, <keyName>Hash, <valName>, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))>);
					'		
					'		<if (isOptionEnabled(setup, useStructuralEquality())) {><if (n == 0) {>result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNodeAtEnd(i))>);<} else {><intercalate(" else ", [ "if (mask \< <nodePosName><j>) { result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNode(i, j))>); }" | j <- [1..n+1] ])> else {
					'			result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNodeAtEnd(i))>);
					'		}<}><} else {>result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNodeAtEnd(i))>);<}>
					'	}
					'}"; 
		
			case \set():
				return 
					"if (mask == <keyPosName><i>) {
					'	if (<eq("<keyName>", "<keyName><i>")>) {
					'		result = <ts.ResultStr>.unchanged(this);
					'	} else {
					'		// merge into node
					'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> node = mergeNodes(<keyName><i>, <keyName><i>.hashCode(), <keyName>, <keyName>Hash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))>);
					'		
					'		<if (n == 0) {>result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNodeAtEnd(i))>);<} else {><intercalate(" else ", [ "if (mask \< <nodePosName><j>) { result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNode(i, j))>); }" | j <- [1..n+1] ])> else {
					'			result = <ts.ResultStr>.modified(<nodeOf(n+1, m-1, replaceValueByNodeAtEnd(i))>);
					'		}<}>
					'	}
					'}"; 
					
			default:
				throw "You forgot <ds>!";			
		}
	};
			
	updated_clause_node = str (int i) { 
		switch (ds) {		
			case \map():
				return 
					"if (mask == <nodePosName><i>) {
					'	final Result<ResultGenerics> <nestedResult> = <nodeName><i>.updated(
					'					mutator, key, keyHash, val, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
					'
					'	if (<nestedResult>.isModified()) {
					'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <nodeOf(n, m, use(replace(generateMembers(n, m), subnodePair(i), [field("mask"), field("<nestedResult>.getNode()")])))>;
					'
					'		if (<nestedResult>.hasReplacedValue()) {
					'			result = <ts.ResultStr>.updated(thisNew, <nestedResult>.getReplacedValue());
					'		} else {
					'			result = <ts.ResultStr>.modified(thisNew);
					'		}
					'	} else {
					'		result = <ts.ResultStr>.unchanged(this);
					'	}
					'}
					"; 
		
			case \set():
				return 
					"if (mask == <nodePosName><i>) {
					'	final Result<ResultGenerics> <nestedResult> = <nodeName><i>.updated(
					'					mutator, key, keyHash, val, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
					'
					'	if (<nestedResult>.isModified()) {
					'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <nodeOf(n, m, use(replace(generateMembers(n, m), subnodePair(i), [field("mask"), field("<nestedResult>.getNode()")])))>;
					'		result = <ts.ResultStr>.modified(thisNew);
					'	} else {
					'		result = <ts.ResultStr>.unchanged(this);
					'	}
					'}
					"; 
					
			default:
				throw "You forgot <ds>!";			
		}
	};
	
	return 
	"final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);
	'final Result<ResultGenerics> result;		
	'		
	'<intercalate(" else ", [ updated_clause_inline(i)| i <- [1..m+1]] + [ updated_clause_node(i)| i <- [1..n+1]])> else {
	'	// no value
	'	<if (isOptionEnabled(setup, useStructuralEquality())) {>result = <ts.ResultStr>.modified(inlineValue(mutator, <use(payloadTriple("mask"))>));<} else {>result = <ts.ResultStr>.modified(<nodeOf(n, m+1, use(generatePayloadMembers(m) + payloadTriple("mask") + generateSubnodeMembers(n)))>);<}>
	'}
	'		
	'return result;";	
}	

bool exists_bodyOf_removed(0, 0, _, _, str(str, str) eq) = true;
str generate_bodyOf_removed(0, 0, _, _, str(str, str) eq)
	= "return <ts.ResultStr>.unchanged(this);"
	;
	
bool exists_bodyOf_removed(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_removed(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;	

bool exists_bodyOf_removed(0, 2, _, _, str(str, str) eq)  = true;
str generate_bodyOf_removed(0, 2, _, _, str(str, str) eq) {
	removed_clause_inline = str (int i) { return 
		"if (mask == <keyPosName><i>) {
		'	if (<eq("<keyName>", "<keyName><i>")>) {
		'		/*
		'		 * Create node with <if (\map() := ts.ds) {>pair<} else {>element<}> <keyName><3 - i><if (\map() := ts.ds) {>, <valName><3 - i><}>. This
		'		 * node will a) either become the new root returned, or b)
		'		 * unwrapped and inlined.
		'		 */
		'		final byte <keyPosName><3 - i>AtShiftZero = (shift == 0) ? <keyPosName><3 - i> : (byte) (keyHash & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);
		'		result = <ts.ResultStr>.modified(<nodeOf(0, 1, use(payloadTriple("<keyPosName><3 - i>AtShiftZero", 3 - i)))>);
		'	} else {
		'		result = <ts.ResultStr>.unchanged(this);
		'	}
		'}";
	};
		
	return 
	"final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);
	'final Result<ResultGenerics> result;		
	'		
	'<intercalate(" else ", [ removed_clause_inline(i) | i <- [1..3]])> else {
	'	result = <ts.ResultStr>.unchanged(this);
	'}
	'
	'return result;";		
}

default bool exists_bodyOf_removed(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_removed(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq) {	
	removed_clause_inline = str (int i) { return 
		"if (mask == <keyPosName><i>) {
		'	if (<eq("<keyName>", "<keyName><i>")>) {
		'		// remove <keyName><i>, <valName><i>
		'		result = <ts.ResultStr>.modified(<nodeOf(n, m-1, use(generateMembers(n, m) - payloadTriple(i)))>);
		'	} else {
		'		result = <ts.ResultStr>.unchanged(this);
		'	}
		'}";
	};

	removed_clause_node = str (int i) { return 
		"if (mask == <nodePosName><i>) {
		'	final Result<ResultGenerics> <nestedResult> = <nodeName><i>.removed(
		'					mutator, key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
		'
		'	if (<nestedResult>.isModified()) {
				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> updatedNode = <nestedResult>.getNode();

				switch (updatedNode.sizePredicate()) {
				<if (n == 1 && m == 0) {>case SIZE_EMPTY:
				case SIZE_ONE:
					// escalate (singleton or empty) result
					result = <nestedResult>;
					break;< } else {> case SIZE_ONE:
					// inline sub-node value
					<if (isOptionEnabled(setup, useStructuralEquality())) {>result = <ts.ResultStr>.modified(removeNode<i>AndInlineValue(mutator, <use(payloadTriple("mask", "updatedNode.getKey(0)", "updatedNode.getValue(0)"))>));<} else {>result = <ts.ResultStr>.modified(<nodeOf(n-1, m+1, use(payloadTriple("mask", "updatedNode.getKey(0)", "updatedNode.getValue(0)") + generateMembers(n, m) - subnodePair(i)))>);<}>
					break;<}>
					
				case SIZE_MORE_THAN_ONE:
					// update <nodeName><i>
					result = <ts.ResultStr>.modified(<nodeOf(n, m, use(replace(generateMembers(n, m), subnodePair(i), [field("mask"), field("updatedNode")])))>);
					break;

				default:
					throw new IllegalStateException(\"Size predicate violates node invariant.\");
				}
		'	} else {
		'		result = <ts.ResultStr>.unchanged(this);
		'	}
		'}"; 
	};
	
	return 
	"final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);
	'final Result<ResultGenerics> result;		
	'		
	'<intercalate(" else ", [ removed_clause_inline(i)| i <- [1..m+1]] + [ removed_clause_node(i)| i <- [1..n+1]])> else {
	'	result = <ts.ResultStr>.unchanged(this);
	'}
	'
	'return result;";
}
		
bool exists_bodyOf_containsKey(0, 0, _, _, str(str, str) eq)  = true;
str generate_bodyOf_containsKey(0, 0, _, _, str(str, str) eq) 
	= "return false;"
	;
	
bool exists_bodyOf_containsKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_containsKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;

default bool exists_bodyOf_containsKey(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_containsKey(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq) 
	= "final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);\n\n"	
	+ intercalate(" else ", 
		["if(mask == <keyPosName><i>) { return <eq("<keyName>", "<keyName><i>")>; }" | i <- [1..m+1]] +
		["if(mask == <nodePosName><i>) { return <nodeName><i>.containsKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>); }" | i <- [1..n+1]])
	+ " else { return false; }"
	;

/* binary search version */
//default bool exists_bodyOf_containsKey(int n, int m, DataStructure ds, str(str, str) eq) = true;
//str generate_bodyOf_containsKey(int n, int m, DataStructure ds, str(str, str) eq)
//	= 
//	"final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);\n\n
//	'<generate_bodyOf_containsKey_binarySearchPayload(1, m, eq)>
//	'<generate_bodyOf_containsKey_binarySearchNode(1, n, eq)>
//	"	
//	;



bool exists_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq) =
	"return false;"
when left > right;	


bool exists_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq) =
	"/*<left>..<right>*/
	'if (mask == <nodePosName><left>) {
	'	return <nodeName><left>.containsKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);	
	'} else {
	'	return false;	
	'}"
when left == right;	

bool exists_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq) =
	"/*<left>..<right>*/
	'if (mask == <nodePosName><left>) {
	'	/*<left>..<left>*/
	'	return <nodeName><left>.containsKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);	
	'} else {
	'	/*<right>..<right>*/
	'	if (mask == <nodePosName><right>) {
	'		return <nodeName><right>.containsKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);			
	'	} else {
	'		return false;
	'	}	
	'}"
when left == right - 1;	
	
default bool exists_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq)  = true;
default str generate_bodyOf_containsKey_binarySearchNode(int left, int right, str(str, str) eq) { 	
 	int pivot = (left + right) / 2;
 	
 	//println("<left>, <pivot>, <right>");
 
	return 
	"/*<left>..<right>*/
	'if (mask \<= <nodePosName><pivot>) {
	'	/*<left>..<pivot>*/	
	'	if (mask == <nodePosName><pivot>) {
	'		/*<pivot>..<pivot>*/
	'		return <nodeName><pivot>.containsKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);	
	'	} else {
	'		<generate_bodyOf_containsKey_binarySearchNode(left, pivot - 1, eq)>	
	'	}
	'} else {
	'	<generate_bodyOf_containsKey_binarySearchNode(pivot + 1, right, eq)>
	'}";	
}







bool exists_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq) =
	"//return false;"
when left > right;	


bool exists_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq) =
	"/*<left>..<right>*/
	'if (mask == <keyPosName><left> && <eq("<keyName>", "<keyName><left>")>) {
	'	return true;	
	'//} else {
	'//	return false;	
	'}"
when left == right;	

bool exists_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq)  = true;
str generate_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq) =
	"/*<left>..<right>*/
	'if (mask == <keyPosName><left> && <eq("<keyName>", "<keyName><left>")>) {
	'	/*<left>..<left>*/
	'	return true;	
	'} else {
	'	/*<right>..<right>*/
	'	if (mask == <keyPosName><right> && <eq("<keyName>", "<keyName><right>")>) {
	'		return true;			
	'	//} else {
	'	//	return false;
	'	}	
	'}"
when left == right - 1;	
	
default bool exists_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq)  = true;
default str generate_bodyOf_containsKey_binarySearchPayload(int left, int right, str(str, str) eq) { 	
 	int pivot = (left + right) / 2;
 	
 	//println("<left>, <pivot>, <right>");
 
	return 
	"/*<left>..<right>*/
	'if (mask \<= <keyPosName><pivot>) {
	'	/*<left>..<pivot>*/	
	'	if (mask == <keyPosName><pivot> && <eq("<keyName>", "<keyName><pivot>")>) {
	'		/*<pivot>..<pivot>*/
	'		return true;	
	'	} else {
	'		<generate_bodyOf_containsKey_binarySearchPayload(left, pivot - 1, eq)>	
	'	}
	'} else {
	'	<generate_bodyOf_containsKey_binarySearchPayload(pivot + 1, right, eq)>
	'}";	
}














	
bool exists_bodyOf_findByKey(0, 0, _, _, str(str, str) eq)  = true;
str generate_bodyOf_findByKey(0, 0, _, _, str(str, str) eq) 
	= "return Optional.empty();"
	;

bool exists_bodyOf_findByKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_findByKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;

default bool exists_bodyOf_findByKey(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_findByKey(int n, int m, DataStructure ds, rel[Option,bool] setup, str(str, str) eq) 
	= "final byte mask = (byte) ((keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);\n\n"	
	+ intercalate(" else ", 
		["if(mask == <keyPosName><i> && <eq("<keyName>", "<keyName><i>")>) { return Optional.of(<if (\map() := ts.ds) {>entryOf(<keyName><i>, <valName><i>)<} else {><keyName><i><}>); }" | i <- [1..m+1]] +
		["if(mask == <nodePosName><i>) { return <nodeName><i>.findByKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>); }" | i <- [1..n+1]])
	+ " else { return Optional.empty(); }"
	;	
			
str generateGenericNodeClassString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) =
	"private static final class Index<n>Node<GenericsStr(ts.tupleTypes)> extends <CompactNode(ds)><GenericsStr(ts.tupleTypes)> {
	'	<for (i <- [1..n+1]) {>
	'	private final byte <nodePosName><i>;
	'	private final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> <nodeName><i>;
	'	<}>	
	
	'	Index<n>Node(<for (i <- [1..n+1]) {>final byte <nodePosName><i>, final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> <nodeName><i><if (i != n) {>, <}><}>) {					
	'		<intercalate("\n\n", ["this.<nodePosName><i> = <nodePosName><i>; this.<nodeName><i> = <nodeName><i>;" | i <- [1..n+1]])>
	'	}
	
	'	<toString(UNCHECKED_ANNOTATION())>	
	'	@Override
	'	Result<ResultGenerics> updated(AtomicReference\<Thread\> mutator, K <keyName>, int <keyName>Hash, V <valName>, int shift) {
	'		<generate_bodyOf_GenericNode_updated(n, m, equalityDefault)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>	
	'	@Override
	'	Result<ResultGenerics> updated(AtomicReference\<Thread\> mutator, K <keyName>, int <keyName>Hash, V <valName>, int shift, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_GenericNode_updated(n, m, equalityComparator)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>	
	'	@Override
	'	Result<ResultGenerics> removed(AtomicReference\<Thread\> mutator, K <keyName>, int <keyName>Hash, int shift) {
	'		<generate_bodyOf_GenericNode_removed(n, m, equalityDefault)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>	
	'	@Override
	'	Result<ResultGenerics> removed(AtomicReference\<Thread\> mutator, K <keyName>, int <keyName>Hash, int shift, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_GenericNode_removed(n, m, equalityComparator)>
	'	}
	
	'	<toString(UNCHECKED_ANNOTATION())>
	'	@Override
	'	boolean <containsKeyMethodName(ds)>(Object <keyName>, int <keyName>Hash, int shift) {
	'		<generate_bodyOf_GenericNode_containsKey(n, m, equalityDefault)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>
	'	@Override
	'	boolean <containsKeyMethodName(ds)>(Object <keyName>, int <keyName>Hash, int shift, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_GenericNode_containsKey(n, m, equalityComparator)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>
	'	@Override
	'	Optional<MapsToGenerics> findByKey(Object <keyName>, int <keyName>Hash, int shift) {
	'		<generate_bodyOf_GenericNode_findByKey(n, m, equalityDefault)>
	'	}

	'	<toString(UNCHECKED_ANNOTATION())>
	'	@Override
	'	Optional<MapsToGenerics> findByKey(Object <keyName>, int <keyName>Hash, int shift, Comparator\<Object\> cmp) {
	'		<generate_bodyOf_GenericNode_findByKey(n, m, equalityComparator)>
	'	}

	'	@Override
	'	<AbstractNode(ds)><GenericsStr(ts.tupleTypes)> getNode(int index) {
	'		<generate_bodyOf_getNode(n)>
	'	}

	'	@Override
	'	int nodeArity() {
	'		return <n>;
	'	}
	}
	";

bool exists_bodyOf_hasSlots(0)  = true;
str generate_bodyOf_hasSlots(0) = 
	"return false;";
	
default bool exists_bodyOf_hasSlots(int mn)  = true;
default str generate_bodyOf_hasSlots(int mn) = 	
	"return true;";
	
bool exists_bodyOf_getSlot(TrieSpecifics ts, 0) = true;
str generate_bodyOf_getSlot(TrieSpecifics ts, 0)
	= "throw new IllegalStateException(\"Index out of range.\");"
when isOptionEnabled(ts.setup,useUntypedVariables())
	;
	
bool exists_bodyOf_getSlot(TrieSpecifics ts, int mn)  = true;
str generate_bodyOf_getSlot(TrieSpecifics ts, int mn) = 	
	"		switch(index) {
	'			<for (i <- [0..mn]) {>case <i>:
	'				return <slotName><i>;
	'			<}>default:
	'				throw new IllegalStateException(\"Index out of range.\");
	'			}"
when isOptionEnabled(ts.setup,useUntypedVariables())
	;
	
bool exists_bodyOf_getSlot(TrieSpecifics ts, int mn)  = true;
str generate_bodyOf_getSlot(TrieSpecifics ts, int mn) = 	
	"final int boundary = TUPLE_LENGTH * payloadArity();
	'
	'if (index \< boundary) {
	'	if (index % 2 == 0) {
	'		return getKey(index / 2);
	'	} else {
	'		return getValue(index / 2);
	'	}
	'} else {
	'	return getNode(index - boundary);
	'}"
when !isOptionEnabled(ts.setup,useUntypedVariables()) && \map() := ts.ds
	;
	
bool exists_bodyOf_getSlot(TrieSpecifics ts, int mn)  = true;
str generate_bodyOf_getSlot(TrieSpecifics ts, int mn) = 	
	"final int boundary = payloadArity();
	'
	'if (index \< boundary) {
	'	return getKey(index);
	'} else {
	'	return getNode(index - boundary);
	'}"
when !isOptionEnabled(ts.setup,useUntypedVariables()) && ts.ds == \set()
	;	
	
default bool exists_bodyOf_getSlot(TrieSpecifics ts, int mn)  = true;
default str generate_bodyOf_getSlot(TrieSpecifics ts, int mn) =	
	"throw new UnsupportedOperationException();"
	;
	
bool exists_bodyOf_getNode(0) = true;
str generate_bodyOf_getNode(0)
	= "throw new IllegalStateException(\"Index out of range.\");"
	;
	
default bool exists_bodyOf_getNode(int n)  = true;
default str generate_bodyOf_getNode(int n) = 	
	"		switch(index) {
	'			<for (i <- [1..n+1]) {>case <i-1>:
	'				return <nodeName><i>;
	'			<}>default:
	'				throw new IllegalStateException(\"Index out of range.\");
	'			}"
	;	
	
bool exists_bodyOf_getKey(0) = true;
str generate_bodyOf_getKey(0)
	= "throw new IllegalStateException(\"Index out of range.\");"
	;
	
default bool exists_bodyOf_getKey(int m)  = true;
default str generate_bodyOf_getKey(int m) = 	
	"		switch(index) {
	'			<for (i <- [1..m+1]) {>case <i-1>:
	'				return <keyName><i>;
	'			<}>default:
	'				throw new IllegalStateException(\"Index out of range.\");
	'			}"
	;

bool exists_bodyOf_getValue(0) = true;
str generate_bodyOf_getValue(0)
	= "throw new IllegalStateException(\"Index out of range.\");"
	;
	
default bool exists_bodyOf_getValue(int m)  = true;
default str generate_bodyOf_getValue(int m) = 	
	"		switch(index) {
	'			<for (i <- [1..m+1]) {>case <i-1>:
	'				return <valName><i>;
	'			<}>default:
	'				throw new IllegalStateException(\"Index out of range.\");
	'			}"
	;

bool exists_bodyOf_copyAndSetValue(_, 0, _, setup) = true;
str generate_bodyOf_copyAndSetValue(_, 0, _, setup)
	= "throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;

bool exists_bodyOf_copyAndSetValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndSetValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	<dec(field(primitive("int"), "idx"))> = dataIndex(bitpos);
	'	
	'	<dec(ts.bitmapField)> = this.<use(bitmapMethod)>;
	'	<dec(ts.valmapField)> = this.<use(valmapMethod)>;
	'	
	'	switch(idx) {
	'		<for (i <- [0..mn/tupleLength(ds)]) {>case <i>:
	'			return <nodeOf(n, m, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ slot(tupleLength(ds)*i+1) ], [ field(valName) ])))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");
	'	}"
when isOptionEnabled(setup,useUntypedVariables())	
	;
	
default bool exists_bodyOf_copyAndSetValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
str generate_bodyOf_copyAndSetValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 	
	"	<dec(field(primitive("int"), "idx"))> = dataIndex(bitpos);
	'	
	'	<dec(ts.bitmapField)> = this.<use(bitmapMethod)>;
	'	<dec(ts.valmapField)> = this.<use(valmapMethod)>;
	'	
	'	switch(idx) {
	'		<for (i <- [1..m+1]) {>case <i-1>:
	'			return <nodeOf(n, m, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ val(ts.valType, i) ], [ field(valName) ])))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");
	'	}"
	;
	
bool exists_bodyOf_copyAndSetNode(0, _, _, setup) = true;
str generate_bodyOf_copyAndSetNode(0, _, _, setup)
	= "throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;
	
bool exists_bodyOf_copyAndSetNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndSetNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 
	"	<dec(field(primitive("int"), "idx"))> = <use(tupleLengthConstant)> * payloadArity() + nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = this.<use(bitmapMethod)>;
	'	<dec(ts.valmapField)> = this.<use(valmapMethod)>;
	'	
	'	switch(idx) {
	'		<for (i <- [0..mn]) {>case <i>:
	'			return <nodeOf(n, m, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ slot(i) ], [ field(nodeName) ])))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"	
when isOptionEnabled(setup,useUntypedVariables())
	;	
	
default bool exists_bodyOf_copyAndSetNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_copyAndSetNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 
	"	final int index = nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = this.<use(bitmapMethod)>;
	'	<dec(ts.valmapField)> = this.<use(valmapMethod)>;
	'	
	'	switch(index) {
	'		<for (i <- [1..n+1]) {>case <i-1>:
	'			return <nodeOf(n, m, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ \node(ts.ds, ts.tupleTypes, i) ], [ field(nodeName) ])))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"	
	;

// TODO: check condition carefully
bool exists_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	"throw new IllegalStateException();"
when !isOptionEnabled(setup,useUntypedVariables()) && ((n + m) == nMax) ||
		isOptionEnabled(setup,useUntypedVariables()) && (mn > tupleLength(ds) * (nMax - 1));
		
bool exists_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	<dec(field(primitive("int"), "idx"))> = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)>);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> | bitpos);
	'
	'	switch(idx) {
	'		<for (i <- [0..mn/tupleLength(ds)]) {>case <i>:
	'			return <nodeOf(n, m+1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*i), ts.payloadTuple + __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*i))))>;
	'		<}>case <mn/tupleLength(ds)>:
	'			return <nodeOf(n, m+1, use(insertBeforeOrDefaultAtEnd(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ slot(tupleLength(ds)*ceil(mn/tupleLength(ds))) ], ts.payloadTuple )))>;
	'		default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables())	
	;	

default bool exists_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_copyAndInsertValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 	
	"	final int valIndex = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)>);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> | bitpos);
	'
	'	switch(valIndex) {
	'		<for (i <- [1..m+1]) {>case <i-1>:
	'			return <nodeOf(n, m+1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup), __payloadTuple(ts.ds, ts.tupleTypes, i), ts.payloadTuple + __payloadTuple(ts.ds, ts.tupleTypes, i) )))>;
	'		<}>case <m>:
	'			return <nodeOf(n, m+1, use(insertBeforeOrDefaultAtEnd(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ \node(ts.ds, ts.tupleTypes, 1) ], ts.payloadTuple )))>;
	'		default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"	
	;
	

bool exists_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n)
	= "throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables()) && (n + m ) >= nMax
	;	

bool exists_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	"	<dec(field(primitive("int"), "idx"))> = nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> | bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)>);
	'
	'	switch(idx) {
	'		<for (i <- [1..n+2]) {>case <i-1>:
	'			return <nodeOf(n+1, m, use(insertBeforeOrDefaultAtEnd(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ \node(ts.ds, ts.tupleTypes, i) ], [ \node(ts.ds, ts.tupleTypes) ] )))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when !isOptionEnabled(setup,useUntypedVariables()) && (n + m ) < nMax
	;	
	
bool exists_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n)
	= "throw new IllegalStateException(\"Index out of range.\");"
when isOptionEnabled(setup,useUntypedVariables()) && (mn >= tupleLength(ds) * nMax)
	;	
	
bool exists_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndInsertNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	<dec(field(primitive("int"), "idx"))> = <use(tupleLengthConstant)> * payloadArity() + nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> | bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)>);
	'
	'	switch(idx) {
	'		<for (i <- [0..mn+1]) {>case <i>:
	'			return <nodeOf(n, m+1, use(insertBeforeOrDefaultAtEnd(metadataArguments(ts) + contentArguments(n, m, ts, setup), [ slot(i) ], [ \node(ts.ds, ts.tupleTypes) ] )))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables()) && (mn < tupleLength(ds) * nMax)
	;
	
	
bool exists_bodyOf_copyAndRemoveNode(int n:0, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndRemoveNode(int n:0, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n)
	= "throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;	

bool exists_bodyOf_copyAndRemoveNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndRemoveNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	"	<dec(field(primitive("int"), "idx"))> = nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> ^ bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)>);
	'
	'	switch(idx) {
	'		<for (i <- [1..n+1]) {>case <i-1>:
	'			return <nodeOf(n-1, m, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - [ \node(ts.ds, ts.tupleTypes, i) ]))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when !isOptionEnabled(setup,useUntypedVariables())
	;
	
bool exists_bodyOf_copyAndRemoveNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndRemoveNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	<dec(field(primitive("int"), "idx"))> = <use(tupleLengthConstant)> * payloadArity() + nodeIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> ^ bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)>);
	'
	'	switch(idx) {
	'		<for (i <- [0..mn]) {>case <i>:
	'			return <nodeOf(n, m+1, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - [ slot(i) ]))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables())	
	;			
	
bool exists_bodyOf_copyAndRemoveValue(_, 0, _, setup) = true;
str generate_bodyOf_copyAndRemoveValue(_, 0, _, setup)
	= "throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;

default bool exists_bodyOf_copyAndRemoveValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
default str generate_bodyOf_copyAndRemoveValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	final int valIndex = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)>);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> ^ bitpos);
	'
	'	switch(valIndex) {
	'		<for (i <- [0..mn/tupleLength(ds)]) {>case <i>:
	'			return <nodeOf(n, m-1, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*i)))>;
			<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables())	
	;
	
default bool exists_bodyOf_copyAndRemoveValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_copyAndRemoveValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 	
	"	final int valIndex = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)>);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> ^ bitpos);
	'
	'	switch(valIndex) {
	'		<for (i <- [1..m+1]) {>case <i-1>:
	'			return <nodeOf(n, m-1, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __payloadTuple(ts.ds, ts.tupleTypes, i)))>;
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
	;	
	
bool exists_bodyOf_copyAndMigrateFromInlineToNode(n, m:0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndMigrateFromInlineToNode(n, m:0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	"throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;
	
bool exists_bodyOf_copyAndMigrateFromInlineToNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndMigrateFromInlineToNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	<dec(field(primitive("int"), "bitIndex"))> = <use(tupleLengthConstant)> * (payloadArity() - 1) + nodeIndex(bitpos);
	'	<dec(field(primitive("int"), "valIndex"))> = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> | bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> ^ bitpos);
	'
	'	switch(valIndex) {
	'		<for (i <- [0..mn/tupleLength(ds)]) {>case <i>:
	'			switch(bitIndex) {
	'				<for (j <- [tupleLength(ds)*(i+1)..mn]) {>case <j-tupleLength(ds)>:
	'					return <nodeOf(n+1, m-1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*i), [ slot(j) ], [ field(nodeName), slot(j) ])))>;
	'				<}>case <mn-tupleLength(ds)>:
	'					return <nodeOf(n+1, m-1, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*i) + [ field(nodeName) ]))>;
	'				default:
	'					throw new IllegalStateException(\"Index out of range.\");	
	'			}
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables())
	;
	
default bool exists_bodyOf_copyAndMigrateFromInlineToNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_copyAndMigrateFromInlineToNode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 	
	"	final int bitIndex = nodeIndex(bitpos);
	'	final int valIndex = dataIndex(bitpos);
	'
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> | bitpos);
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> ^ bitpos);
	'
	'	switch(valIndex) {
	'		<for (i <- [1..m+1]) {>case <i-1>:
	'			switch(bitIndex) {
	'				<for (j <- [1..n+1]) {>case <j-1>:
	'					return <nodeOf(n+1, m-1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __payloadTuple(ts.ds, ts.tupleTypes, i), [ \node(ts.ds, ts.tupleTypes, j) ], [ field(nodeName), \node(ts.ds, ts.tupleTypes, j) ])))>;
	'				<}>case <n>:
	'					return <nodeOf(n+1, m-1, use(metadataArguments(ts) + contentArguments(n, m, ts, setup) - __payloadTuple(ts.ds, ts.tupleTypes, i) + [ field(nodeName) ]))>;
	'				default:
	'					throw new IllegalStateException(\"Index out of range.\");	
	'			}
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
	;


bool exists_bodyOf_copyAndMigrateFromNodeToInline(n:0, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndMigrateFromNodeToInline(n:0, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =	
	"throw new IllegalStateException(\"Index out of range.\");"
when !isOptionEnabled(setup,useUntypedVariables())
	;
	
//bool exists_bodyOf_copyAndMigrateFromNodeToInline(n, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
//str generate_bodyOf_copyAndMigrateFromNodeToInline(n, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 
//	"throw new IllegalStateException(\"Index out of range.\");"
//when isOptionEnabled(setup,useUntypedVariables())
//	;	

bool exists_bodyOf_copyAndMigrateFromNodeToInline(n, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndMigrateFromNodeToInline(n, m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	"throw new IllegalStateException(\"Index out of range.\");"
when isOptionEnabled(setup,useUntypedVariables()) && (mn == tupleLength(ds) * nMax)
	;
				
bool exists_bodyOf_copyAndMigrateFromNodeToInline(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_copyAndMigrateFromNodeToInline(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = 	
	"	final int bitIndex = nodeIndex(bitpos);
	'	final int valIndex = dataIndex(bitpos);
	'	
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> ^ bitpos);	
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> | bitpos);
	'
	'	<dec(key(ts.keyType))> = <nodeName>.getKey(0);
	'	<if (\map() := ts.ds) {><dec(val(ts.valType))> = <nodeName>.getValue(0);<}>	
	'
	'	switch(bitIndex) {
	'		<for (i <- [0..mn]) {>case <i>:
	'			switch(valIndex) {
	'				<for (j <- [0..i/2]) {>case <j>:
	'					return <nodeOf(n-1, m+1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup) - [ slot(i) ], __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*j), ts.payloadTuple + __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*j))))>;
	'				<}>case <i/2>:
	'					return <nodeOf(n-1, m+1, use([ bitmapField, valmapField ] + insertAfterOrDefaultAtFront(contentArguments(n, m, ts, setup) - [ slot(i) ], __untypedPayloadTuple(ts.ds, ts.tupleTypes, tupleLength(ds)*(i/2-1)), ts.payloadTuple)))>;
	'				default:
	'					throw new IllegalStateException(\"Index out of range.\");	
	'			}
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
when isOptionEnabled(setup,useUntypedVariables())	
	;	
	
default bool exists_bodyOf_copyAndMigrateFromNodeToInline(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_copyAndMigrateFromNodeToInline(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) = 	
	"	final int bitIndex = nodeIndex(bitpos);
	'	final int valIndex = dataIndex(bitpos);
	'	
	'	<dec(ts.bitmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(bitmapMethod)> ^ bitpos);	
	'	<dec(ts.valmapField)> = (<typeToString(chunkSizeToPrimitive(bitPartitionSize))>) (this.<use(valmapMethod)> | bitpos);
	'
	'	<dec(key(ts.keyType))> = <nodeName>.getKey(0);
	'	<if (\map() := ts.ds) {><dec(val(ts.valType))> = <nodeName>.getValue(0);<}>	
	'
	'	switch(bitIndex) {
	'		<for (i <- [1..n+1]) {>case <i-1>:
	'			switch(valIndex) {
	'				<for (j <- [1..m+1]) {>case <j-1>:
	'					return <nodeOf(n-1, m+1, use(replace(metadataArguments(ts) + contentArguments(n, m, ts, setup) - [ \node(ts.ds, ts.tupleTypes, i) ], __payloadTuple(ts.ds, ts.tupleTypes, j), ts.payloadTuple + __payloadTuple(ts.ds, ts.tupleTypes, j))))>;
	'				<}>case <m>:
	'					return <nodeOf(n-1, m+1, use([ bitmapField, valmapField ] + insertAfterOrDefaultAtFront(contentArguments(n, m, ts, setup) - [ \node(ts.ds, ts.tupleTypes, i) ], __payloadTuple(ts.ds, ts.tupleTypes, m), ts.payloadTuple)))>;
	'				default:
	'					throw new IllegalStateException(\"Index out of range.\");	
	'			}
	'		<}>default:
	'			throw new IllegalStateException(\"Index out of range.\");	
	'	}"
	;

	
bool exists_bodyOf_getKeyValueEntry(TrieSpecifics ts, 0) = true;
str generate_bodyOf_getKeyValueEntry(TrieSpecifics ts, 0)
	= "throw new IllegalStateException(\"Index out of range.\");"
	;
	
default bool exists_bodyOf_getKeyValueEntry(TrieSpecifics ts, int m)  = true;
default str generate_bodyOf_getKeyValueEntry(TrieSpecifics ts, int m) = 	
	"		switch(index) {
	'			<for (i <- [1..m+1]) {>case <i-1>:
	'				return (java.util.Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>) entryOf(<keyName><i>, <valName><i>);
	'			<}>default:
	'				throw new IllegalStateException(\"Index out of range.\");
	'			}"
	;
			
str generateCompactNodeString() = 
	"private static abstract class <CompactNode(ds)><GenericsStr(ts.tupleTypes)> extends <AbstractNode(ds)><GenericsStr(ts.tupleTypes)> {

		<toString(UNCHECKED_ANNOTATION())>
		static final AbstractNode EMPTY_INDEX_NODE = new IndexNode(0, new AbstractNode[0], 0);

		<toString(UNCHECKED_ANNOTATION())>
		static <GenericsStr(ts.tupleTypes)> <CompactNode(ds)><GenericsStr(ts.tupleTypes)> mergeNodes(<CompactNode(ds)><GenericsStr(ts.tupleTypes)> node0, int hash0,
						<CompactNode(ds)><GenericsStr(ts.tupleTypes)> node1, int hash1, int shift) {
			final int mask0 = (hash0 \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;
			final int mask1 = (hash1 \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;

			if (mask0 != mask1) {
				// both nodes fit on same level
				final int bitmap = (1 \<\< mask0) | (1 \<\< mask1);
				final <AbstractNode(ds)><GenericsStr(ts.tupleTypes)>[] nodes = new AbstractNode[2];

				if (mask0 \< mask1) {
					nodes[0] = node0;
					nodes[1] = node1;
				} else {
					nodes[0] = node1;
					nodes[1] = node0;
				}

				return new IndexNode\<\>(bitmap, nodes, node0.size() + node1.size());
			} else {
				// values fit on next level
				final int bitmap = (1 \<\< mask0);
				final <AbstractNode(ds)><GenericsStr(ts.tupleTypes)> node = mergeNodes(node0, hash0, node1, hash1, shift
								+ <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))>);

				return new IndexNode\<\>(bitmap, node, node.size());
			}
		}
	}"
	;
	
bool exists_bodyOf_GenericNode_containsKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_GenericNode_containsKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;	
	
default bool exists_bodyOf_GenericNode_containsKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_GenericNode_containsKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq) = 
	"final int mask = (<keyName>Hash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;
	'
	'if ((valmap & bitpos) != 0) {
	'	return <eq("nodes[dataIndex(bitpos)]", keyName)>;
	'}
	'
	'if ((bitmap & bitpos) != 0) {
	'	return ((<AbstractNode(ds)><GenericsStr(ts.tupleTypes)>) nodes[bitIndex(bitpos)]).containsKey(<keyName>, <keyName>Hash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
	'}
	'
	'return false;"
	;
	
bool exists_bodyOf_GenericNode_findByKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_GenericNode_findByKey(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;		
	
default bool exists_bodyOf_GenericNode_findByKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_GenericNode_findByKey(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq) = 
	"final int mask = (keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;

	'if ((valmap & bitpos) != 0) { // inplace value
	'	final int valIndex = dataIndex(bitpos);
	'
	'	if (<eq("nodes[valIndex]", keyName)>) {
	'		final K _key = (K) nodes[valIndex];
	'		final V _val = (V) nodes[valIndex + 1];
	'
	'		final Map.Entry<GenericsStr(ts.tupleTypes)> entry = entryOf(_key, _val);
	'		return Optional.of(entry);
	'	}
	'
	'	return Optional.empty();
	'}
	'
	'if ((bitmap & bitpos) != 0) { // node (not value)
	'	final <AbstractNode(ds)><GenericsStr(ts.tupleTypes)> subNode = ((<AbstractNode(ds)><GenericsStr(ts.tupleTypes)>) nodes[bitIndex(bitpos)]);
	'
	'	return subNode.findByKey(key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
	'}
	'
	'return Optional.empty();"
	;
	
bool exists_bodyOf_GenericNode_updated(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_GenericNode_updated(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;	
	
default bool exists_bodyOf_GenericNode_updated(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_GenericNode_updated(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq) = 
	"final int mask = (keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;
	'<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;
	'
	'if ((valmap & bitpos) != 0) { // inplace value
	'	final int valIndex = dataIndex(bitpos);
	'
	'	final Object currentKey = nodes[valIndex];
	'
	'	if (<eq("currentKey", keyName)>) {
	'		<if (ds == \set()) {>return <ts.ResultStr>.unchanged(this);<} else {>final Object currentVal = nodes[valIndex + 1];
	'
	'		if (<eq("currentVal", valName)>) {
	'			return <ts.ResultStr>.unchanged(this);
	'		}
	'
	'		// update mapping
	'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew;
	'
	'		if (isAllowedToEdit(this.mutator, mutator)) {
	'			// no copying if already editable
	'			this.nodes[valIndex + 1] = val;
	'			thisNew = this;
	'		} else {
	'			final Object[] editableNodes = copyAndSet(this.nodes, valIndex + 1, val);
	'
	'			thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, bitmap, valmap, editableNodes, payloadArity);
	'		}
	'
	'		return <ts.ResultStr>.updated(thisNew, (V) currentVal);<}>
	'	} else {
	'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> nodeNew = mergeNodes((K) nodes[valIndex], nodes[valIndex].hashCode(),<if (\map() := ts.ds) {> (V) nodes[valIndex + 1],<}> key, keyHash,<if (\map() := ts.ds) {> val,<}> shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))>);
	'
	'		final int offset = <if (\map() := ts.ds) {>2 * <}>(payloadArity - 1);
	'		final int index = Integer.bitCount(((bitmap | bitpos) ^ (valmap ^ bitpos)) & (bitpos - 1));
	'
	'		final Object[] editableNodes = copyAndMoveToBack<if (\map() := ts.ds) {>Pair<}>(this.nodes, valIndex, offset + index, nodeNew);
	'
	'		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, bitmap | bitpos, valmap ^ bitpos, editableNodes, (byte) (payloadArity - 1));
	'
	'		return <ts.ResultStr>.modified(thisNew);
	'	}
	'} else if ((bitmap & bitpos) != 0) { // node (not value)
	'	final int bitIndex = bitIndex(bitpos);
	'	final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> subNode = (<CompactNode(ds)><GenericsStr(ts.tupleTypes)>) nodes[bitIndex];
	'
	'	final Result<ResultGenerics> <nestedResult> = subNode.updated(mutator, key, keyHash, val, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);
	'
	'	if (!<nestedResult>.isModified()) {
	'		return <ts.ResultStr>.unchanged(this);
	'	}
	'
	'	final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew;
	'
	'	// modify current node (set replacement node)
	'	if (isAllowedToEdit(this.mutator, mutator)) {
	'		// no copying if already editable
	'		this.nodes[bitIndex] = <nestedResult>.getNode();
	'		thisNew = this;
	'	} else {
	'		final Object[] editableNodes = copyAndSet(this.nodes, bitIndex, <nestedResult>.getNode());
	'
	'		thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, bitmap, valmap, editableNodes, payloadArity);
	'	}
	'
		<if (\map() := ts.ds) {>
	'	if (<nestedResult>.hasReplacedValue()) {
	'		return <ts.ResultStr>.updated(thisNew, <nestedResult>.getReplacedValue());
	'	}
		<}>
	'
	'	return <ts.ResultStr>.modified(thisNew);
	'} else {
	'	// no value
	'	final Object[] editableNodes = copyAndInsert<if (\map() := ts.ds) {>Pair<}>(this.nodes, dataIndex(bitpos), key<if (\map() := ts.ds) {>, val<}>);
	'
	'	final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, bitmap | bitpos, valmap | bitpos, editableNodes, (byte) (payloadArity + 1));
	'
	'	return <ts.ResultStr>.modified(thisNew);
	'}";	
		
bool exists_bodyOf_GenericNode_removed(_, _, _, rel[Option,bool] setup, str(str, str) eq)	 = true;
str generate_bodyOf_GenericNode_removed(_, _, _, rel[Option,bool] setup, str(str, str) eq)	
	= "throw new UnsupportedOperationException();"
when !(isOptionEnabled(setup,methodsWithComparator()) || (eq == equalityDefault))
	;			
		
default bool exists_bodyOf_GenericNode_removed(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq)  = true;
default str generate_bodyOf_GenericNode_removed(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(str, str) eq) =
	"final int mask = (keyHash \>\>\> shift) & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>;
	<dec(ts.bitposField)> = <toString(call(ts.CompactNode_bitpos))>;

	if ((valmap & bitpos) != 0) { // inplace value
		final int valIndex = dataIndex(bitpos);

		if (<eq("nodes[valIndex]", keyName)>) {			
			if (!USE_SPECIALIAZIONS && this.payloadArity() == 2 && this.nodeArity() == 0) {
				/*
				 * Create new node with remaining pair. The new node
				 * will a) either become the new root returned, or b)
				 * unwrapped and inlined during returning.
				 */
				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew;
				final int newValmap = (shift == 0) ? this.valmap ^ bitpos
								: 1L \<\< (keyHash & <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionMask())))>);

				if (valIndex == 0) {
					thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, newValmap,
									newValmap, new Object[] { nodes[2], nodes[3] },
									(byte) (1));
				} else {
					thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, newValmap,
									newValmap, new Object[] { nodes[0], nodes[1] },
									(byte) (1));
				}

				return <ts.ResultStr>.modified(thisNew);
			} else if (USE_SPECIALIAZIONS && this.arity() == <nBound + 1>) {
				final Object[] editableNodes = copyAndRemove<if (\map() := ts.ds) {>Pair<}>(this.nodes, valIndex);
	
				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator,
								this.bitmap ^ bitpos, this.valmap ^ bitpos, editableNodes,
								(byte) (payloadArity - 1));
	
				return <ts.ResultStr>.modified(thisNew.convertToGenericNode());
			} else {
				final Object[] editableNodes = copyAndRemove<if (\map() := ts.ds) {>Pair<}>(this.nodes, valIndex);
	
				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator,
								this.bitmap ^ bitpos, this.valmap ^ bitpos, editableNodes,
								(byte) (payloadArity - 1));
	
				return <ts.ResultStr>.modified(thisNew);
			}
		} else {		
			return <ts.ResultStr>.unchanged(this);
		}
	} else if ((bitmap & bitpos) != 0) { // node (not value)
		final int bitIndex = bitIndex(bitpos);
		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> subNode = (<CompactNode(ds)><GenericsStr(ts.tupleTypes)>) nodes[bitIndex];
		final Result<ResultGenerics> <nestedResult> = subNode.removed(
						mutator, key, keyHash, shift + <toString(call(getDef(ts, trieNode(compactNode()), bitPartitionSize())))><if (!(eq == equalityDefault)) {>, <cmpName><}>);

		if (!<nestedResult>.isModified()) {
			return <ts.ResultStr>.unchanged(this);
		}

		final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> subNodeNew = <nestedResult>.getNode();

		switch (subNodeNew.sizePredicate()) {
		case 0: {
			if (!USE_SPECIALIAZIONS && this.payloadArity() == 0 && this.nodeArity() == 1) {
				// escalate (singleton or empty) result
				return <nestedResult>;
			} else if (USE_SPECIALIAZIONS && this.arity() == <nBound + 1>) {
				// remove node
				final Object[] editableNodes = copyAndRemove<if (\map() := ts.ds) {>Pair<}>(this.nodes, bitIndex);

				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator,
								bitmap ^ bitpos, valmap, editableNodes, payloadArity);

				return <ts.ResultStr>.modified(thisNew.convertToGenericNode());
			} else {
				// remove node
				final Object[] editableNodes = copyAndRemove<if (\map() := ts.ds) {>Pair<}>(this.nodes, bitIndex);

				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator,
								bitmap ^ bitpos, valmap, editableNodes, payloadArity);

				return <ts.ResultStr>.modified(thisNew);
			}
		}
		case 1: {
			if (!USE_SPECIALIAZIONS && this.payloadArity() == 0 && this.nodeArity() == 1) {
				// escalate (singleton or empty) result
				return <nestedResult>;
			} else {
				// inline value (move to front)
				final int valIndexNew = Integer.bitCount((valmap | bitpos) & (bitpos - 1));
	
				final Object[] editableNodes = copyAndMoveToFront<if (\map() := ts.ds) {>Pair<}>(this.nodes, bitIndex,
								valIndexNew, subNodeNew.getKey(0)<if (\map() := ts.ds) {>, subNodeNew.getValue(0)<}>);
	
				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator, bitmap,
								valmap | bitpos, editableNodes, (byte) (payloadArity + 1));
	
				return <ts.ResultStr>.modified(thisNew);
			}
		}
		default: {
			// modify current node (set replacement node)
			if (isAllowedToEdit(this.mutator, mutator)) {
				// no copying if already editable
				this.nodes[bitIndex] = subNodeNew;
				return <ts.ResultStr>.modified(this);
			} else {
				final Object[] editableNodes = copyAndSet(this.nodes, bitIndex, subNodeNew);

				final <CompactNode(ds)><GenericsStr(ts.tupleTypes)> thisNew = <CompactNode(ds)>.<GenericsStr(ts.tupleTypes)> nodeOf(mutator,
								bitmap, valmap, editableNodes, payloadArity);

				return <ts.ResultStr>.modified(thisNew);
			}
		}
		}		
	}

	return <ts.ResultStr>.unchanged(this);";

list[Argument] generateMembers(int n, int m, TrieSpecifics ts) 
	= [ *payloadTriple(i) | i <- [1..m+1]] 
	+ [ *subnodePair(i)   | i <- [1..n+1]]
	;

list[Argument] generatePayloadMembers(int m) 
	= [ *payloadTriple(i) | i <- [1..m+1]] 
	;

list[Argument] generateSubnodeMembers(int n) 
	= [ *subnodePair(i)   | i <- [1..n+1]]
	;	


bool exists_valNodeOf_factoryMethod(0, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_valNodeOf_factoryMethod(0, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) { throw "TODO"; }
		
bool exists_valNodeOf_factoryMethod(1, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_valNodeOf_factoryMethod(1, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) { throw "TODO"; }

//Method CompactNode_factoryMethod(int n, int m, TrieSpecifics ts) {
//	// TODO: remove code duplication
//	members = generateMembers(n, m);
//	constructorArgs = ts.mutator + members;
//
//	className = "<toString(ds)><m>To<n>Node";
//	
//	//"static final <GenericsStr(ts.tupleTypes)>
//
//	return method(ts.compactNodeClassReturn, "nodeOf", args = constructorArgs);
//}

bool exists_valNodeOf_factoryMethod(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_valNodeOf_factoryMethod(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) {
	// TODO: remove code duplication
	members = generateMembers(n, m);
	constructorArgs = ts.mutator + members;

	className = "<toString(ds)><m>To<n>Node";

	if ((n + m) <= nBound) {		
		return
		"static final <GenericsStr(ts.tupleTypes)> <CompactNode(ds)><GenericsStr(ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
		'	return new <className>\<\>(<intercalate(", ", mapper(constructorArgs, use))>);
		'}
		"; 
	} else if ((n + m) == nBound + 1 && (n + m) < nMax) {
		list[Argument] keyPosArgs  =  [ keyPos(i) | i <- [1..m+1]];
		list[Argument] nodePosArgs = [ nodePos(j) | j <- [1..n+1]];

		list[Argument] bitmapArgs = [ keyPos(i) | i <- [1..m+1]] + [ nodePos(j) | j <- [1..n+1]];
		list[Argument] valmapArgs = [ keyPos(i) | i <- [1..m+1]];
		
		list[Argument] argsForArray = [];

		if (\map() := ds) {
			argsForArray = [ key(ts.keyType, i), val(ts.valType, i) | i <- [1..m+1]] + [ \node(ts.ds, ts.tupleTypes, j) | j <- [1..n+1]];
		} else { 
			argsForArray = [ key(ts.keyType, i) | i <- [1..m+1]] + [ \node(ts.ds, ts.tupleTypes, j) | j <- [1..n+1]];
		}
		
		if (isOptionEnabled(setup, useStructuralEquality())) {			
			return
			"static final <GenericsStr(ts.tupleTypes)> <CompactNode(ds)><GenericsStr(ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "final <dec(a)>"; }))>) {					
			'	final int bitmap = 0 <intercalate(" ", mapper(bitmapArgs, str(Argument a) { return "| (1 \<\< <use(a)>)"; }))> ;
			'	final int valmap = 0 <intercalate(" ", mapper(valmapArgs, str(Argument a) { return "| (1 \<\< <use(a)>)"; }))> ;
			'
			'	return nodeOf(mutator, bitmap, valmap, new Object[] { <use(argsForArray)> }, (byte) <m>);
			'}
			";
		} else {				
			return 
			"static final <GenericsStr(ts.tupleTypes)> <CompactNode(ds)><GenericsStr(ts.tupleTypes)> nodeOf(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "final <dec(a)>"; }))>) {
			'	final int bitmap = 0 <intercalate(" ", mapper(bitmapArgs, str(Argument a) { return "| (1 \<\< <use(a)>)"; }))> ;
			'	final int valmap = 0 <intercalate(" ", mapper(valmapArgs, str(Argument a) { return "| (1 \<\< <use(a)>)"; }))> ;
			'	final Object[] content = new Object[] { <use(argsForArray)> } ;
			'
			'	<if (m > 1) {>
			'	<if (\map() := ts.ds) {>
			'	// final BitonicSorterForArbitraryN_Pairs sorterPayload = new BitonicSorterForArbitraryN_Pairs();
			'	BitonicSorterForArbitraryN_Pairs.sort(new int[] { <use(keyPosArgs)> }, content, 0);
			'	<} else {>
			'	// final BitonicSorterForArbitraryN_Single sorterPayload = new BitonicSorterForArbitraryN_Single();
			'	BitonicSorterForArbitraryN_Single.sort(new int[] { <use(keyPosArgs)> }, content, 0);			
			'	<}>
			'	<}>
			'	
			'	<if (n > 1) {>
			'	// final BitonicSorterForArbitraryN_Single sorterSubnodes = new BitonicSorterForArbitraryN_Single();
			'	BitonicSorterForArbitraryN_Single.sort(new int[] { <use(nodePosArgs)> }, content, <if (\map() := ts.ds) {><2*m><}else{><m><}>);
			'	<}>
			'
			'	return nodeOf(mutator, bitmap, valmap, content, (byte) <m>);		
			'}
			";			
		}
	} else {
		throw "Arguments out of bounds.";
	}
}
	
str generateSpecializedNodeWithBytePositionsClassString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) {
	members = generateMembers(n, m);
	constructorArgs = ts.mutator + members;

	className = "<toString(ds)><m>To<n>Node";

	return
	"private static final class <className><GenericsStr(ts.tupleTypes)> extends <className_compactNode(ts, setup, n != 0, m != 0)><GenericsStr(ts.tupleTypes)> {
	'	<intercalate("\n", mapper(members, str(Argument a) { 
			str dec = "private final <dec(a)>;";
			
			if (field(_, /.*pos.*/) := a || getter(_, /.*pos.*/) := a) {
				return "\n<dec>";
			} else {
				return dec;
			} 
		}))>
				
	'	<className>(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "final <dec(a)>"; }))>) {		
	'		<intercalate("\n", mapper(members, str(Argument a) { 
				str dec = "this.<use(a)> = <use(a)>;";
				
				if (field(_, /.*pos.*/) := a || getter(_, /.*pos.*/) := a) {
					return "\n<dec>";
				} else {
					return dec;
				} 
			}))>
	'		<if ((n + m) > 0) {>
	'		<}>assert nodeInvariant();
	'	}

	'	@Override
	'	Result<ResultGenerics> updated(AtomicReference\<Thread\> mutator, K key,
	'					int keyHash, V<if (ds == \set()) {>oid<}> val, int shift) {
	'		<generate_bodyOf_updated(n, m, equalityDefault)>
	'	}

	'	@Override
	'	Result<ResultGenerics> updated(AtomicReference\<Thread\> mutator, K key,
	'					int keyHash, V<if (ds == \set()) {>oid<}> val, int shift, Comparator\<Object\> cmp) {
	'		<generate_bodyOf_updated(n, m, equalityComparator)>
	'	}

	'	@Override
	'	Result<ResultGenerics> removed(AtomicReference\<Thread\> mutator, K key,
	'					int keyHash, int shift) {
	'		<generate_bodyOf_removed(n, m, equalityDefault)>
	'	}

	'	@Override
	'	Result<ResultGenerics> removed(AtomicReference\<Thread\> mutator, K key,
	'					int keyHash, int shift, Comparator\<Object\> cmp) {
	'		<generate_bodyOf_removed(n, m, equalityComparator)>
	'	}

	<if (isOptionEnabled(setup, useStructuralEquality())) {>
	'	<if ((n + m) > 0) {>
	'	private <CompactNode(ds)><GenericsStr(ts.tupleTypes)> inlineValue(AtomicReference\<Thread\> mutator, <dec(payloadTriple("mask"))>) {
	'		<generate_bodyOf_inlineValue(n, m)>
	'	}
	'	<}>
	<}>
	
	<if (isOptionEnabled(setup, useStructuralEquality())) {>
	'	<for (j <- [1..n+1]) {>
	'	private <CompactNode(ds)><GenericsStr(ts.tupleTypes)> removeNode<j>AndInlineValue(AtomicReference\<Thread\> mutator, <dec(payloadTriple("mask"))>) {
	'		<generate_bodyOf_removeNodeAndInlineValue(n, m, j)>
	'	}
	'	<}>
	<}>

	'	@Override
	'	boolean <containsKeyMethodName(ds)>(Object key, int keyHash, int shift) {
	'		<generate_bodyOf_containsKey(n, m, equalityDefault)>
	'	}

	'	@Override
	'	boolean <containsKeyMethodName(ds)>(Object key, int keyHash, int shift, Comparator\<Object\> <cmpName>) {
	'		<generate_bodyOf_containsKey(n, m, equalityComparator)>
	'	}

	'	@Override
	'	Optional<MapsToGenerics> findByKey(Object key, int keyHash, int shift) {
	'		<generate_bodyOf_findByKey(n, m, equalityDefault)>
	'	}

	'	@Override
	'	Optional<MapsToGenerics> findByKey(Object key, int keyHash, int shift,
	'					Comparator\<Object\> cmp) {
	'		<generate_bodyOf_findByKey(n, m, equalityComparator)>
	'	}
	
	'	<toString(UNCHECKED_ANNOTATION())>
	'	@Override
	'	Iterator\<<CompactNode(ds)><GenericsStr(ts.tupleTypes)>\> nodeIterator() {
	'		<if (n > 0) {>return ArrayIterator.\<<CompactNode(ds)><GenericsStr(ts.tupleTypes)>\> of(new <CompactNode(ds)>[] { <intercalate(", ", ["<nodeName><i>" | i <- [1..n+1]])> });<} else {>return Collections.emptyIterator();<}>
	'	}

	'	@Override
	'	boolean hasNodes() {
	'		return <if (n > 0) {>true<} else {>false<}>;
	'	}

	'	@Override
	'	int nodeArity() {
	'		return <n>;
	'	}	

	<if (\map() := ts.ds) {>
	'	@Override
	'	SupplierIterator<SupplierIteratorGenerics(ds)> payloadIterator() {
	'		<if (m > 0) {>return ArrayKeyValueSupplierIterator.of(new Object[] { <intercalate(", ", ["<keyName><i>, <valName><i>"  | i <- [1..m+1]])> });<} else {>return EmptySupplierIterator.emptyIterator();<}>
	'	}
	<} else {>
	'	@Override
	'	SupplierIterator<SupplierIteratorGenerics(ds)> payloadIterator() {
	'		<if (m > 0) {>return ArrayKeyValueSupplierIterator.of(new Object[] { <intercalate(", ", ["<keyName><i>, <keyName><i>"  | i <- [1..m+1]])> });<} else {>return EmptySupplierIterator.emptyIterator();<}>
	'	}	
	<}>

	'	@Override
	'	boolean hasPayload() {
	'		return <if (m > 0) {>true<} else {>false<}>;
	'	}

	'	@Override
	'	int payloadArity() {
	'		return <m>;
	'	}
	
	'	@Override
	'	<typeToString(ts.keyType)> headKey() {
	'		<if (m == 0) {>throw new UnsupportedOperationException(\"Node does not directly contain a key.\")<} else {>return key1<}>;
	'	}

	<if (\map() := ts.ds) {>
	'	@Override
	'	<typeToString(ts.valType)> headVal() {
	'		<if (m == 0) {>throw new UnsupportedOperationException(\"Node does not directly contain a value.\")<} else {>return val1<}>;
	'	}	
	<}>
	
	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> getNode(int index) {
	'		<generate_bodyOf_getNode(n)>
	'	}
	
	'	@Override
	'	K getKey(int index) {
	'		<generate_bodyOf_getKey(m)>
	'	}

	<if (\map() := ts.ds) {>
	'	@Override
	'	V getValue(int index) {
	'		<generate_bodyOf_getValue(m)>
	'	}
	<}>
		
	<if (\map() := ts.ds) {>
	'	@Override
	'	Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)> getKeyValueEntry(int index) {
	'		<generate_bodyOf_getKeyValueEntry(ts, m)>
	'	}
	<}>	
	
	'	@Override
	'	byte sizePredicate() {
	'		return <generate_bodyOf_sizePredicate(n, m)>;
	'	}

	<if (isOptionEnabled(setup, useStructuralEquality())) {>
	'	@Override
	'	public int hashCode() {
	'		<if ((n + m) > 0) {>final int prime = 31; int result = 1;<} else {>int result = 1;<}>
	'		<for (i <- [1..m+1]) {>
	'		<if (\map() := ts.ds) {>result = prime * result + <valName><i>.hashCode();<}>
	'		<}><for (i <- [1..n+1]) {>
	'		result = prime * result + <nodePosName><i>;
	'		result = prime * result + <nodeName><i>.hashCode();
	'		<}>	
	'		return result;
	'	}

	'	@Override
	'	public boolean equals(Object other) {
	'		if (null == other) {
	'			return false;
	'		}
	'		if (this == other) {
	'			return true;
	'		}
	'		if (getClass() != other.getClass()) {
	'			return false;
	'		}
	'
	'		<if ((n + m) > 0) {><className><QuestionMarkGenerics(ts.ds, ts.tupleTypes)> that = (<className><QuestionMarkGenerics(ts.ds, ts.tupleTypes)>) other;
	'
	'		<generate_equalityComparisons(n, m, equalityDefault)><}>
	'
	'		return true;
	'	}
	<}>	
	

	'	@Override
	'	public String toString() {		
	'		<if (n == 0 && m == 0) {>return \"[]\";<} else {>return String.format(\"[<intercalate(", ", [ "@%d: %s<if (\map() := ts.ds) {>=%s<}>" | i <- [1..m+1] ] + [ "@%d: %s" | i <- [1..n+1] ])>]\", <use(members)>);<}>
	'	}
	
	'}
	"
	;
}

bool exists_bodyOf_sizePredicate(0, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_bodyOf_sizePredicate(0, 0, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) = "SIZE_EMPTY";
bool exists_bodyOf_sizePredicate(0, 1, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_bodyOf_sizePredicate(0, 1, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) = "SIZE_ONE";	
default bool exists_bodyOf_sizePredicate(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
default str generate_bodyOf_sizePredicate(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) = "SIZE_MORE_THAN_ONE";


bool exists_equalityComparisons(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq, int mn = tupleLength(ds)*m+n) = true;
str generate_equalityComparisons(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq, int mn = tupleLength(ds)*m+n) =
	"if (<use(bitmapMethod)> != that.<use(bitmapMethod)>) {
	'	return false;
	'}
	'if (<use(valmapMethod)> != that.<use(valmapMethod)>) {
	'	return false;
	'}
	'
	'<for (i <- [0..mn]) {>
	'if (!(<eq(key(ts.keyType, "<slotName><i>"), key(ts.keyType, "that.<slotName><i>"))>)) {
	'	return false;
	'}<}>"
when isOptionEnabled(setup,useUntypedVariables())	
	;
	 
bool exists_equalityComparisons(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq)  = true;
str generate_equalityComparisons(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str(Argument, Argument) eq) =
	"if (<use(bitmapMethod)> != that.<use(bitmapMethod)>) {
	'	return false;
	'}
	'if (<use(valmapMethod)> != that.<use(valmapMethod)>) {
	'	return false;
	'}
	'<for (i <- [1..m+1]) {>
	'if (!(<eq(key(ts.keyType, "<keyName><i>"), key(ts.keyType, "that.<keyName><i>"))>)) {
	'	return false;
	'}<if (\map() := ts.ds) {>if (!(<eq(val(ts.valType, "<valName><i>"), val(ts.valType, "that.<valName><i>"))>)) {
	'	return false;
	'}<}><}><for (i <- [1..n+1]) {>
	'if (!(<eq(\node(ts.ds, ts.tupleTypes, "<nodeName><i>"), \node(ts.ds, ts.tupleTypes, "that.<nodeName><i>"))>)) {
	'	return false;
	'}<}>"
	;	 

bool exists_bodyOf_inlineValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
str generate_bodyOf_inlineValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) =
	"return <nodeOf(n, m+1, use(payloadTriple("mask") + generateSubnodeMembers(n)))>;"
when m == 0;

default bool exists_bodyOf_inlineValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound))  = true;
default str generate_bodyOf_inlineValue(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound)) =
	"<intercalate(" else ", [ "if (mask \< <keyPosName><i>) { return <nodeOf(n, m+1, use(insertBeforeOrDefaultAtEnd(generateMembers(n, m), payloadTriple(i), payloadTriple("mask"))))>; }" | i <- [1..m+1] ])> else {
	'	return <nodeOf(n, m+1, use(generatePayloadMembers(m) + payloadTriple("mask") + generateSubnodeMembers(n)))>;
	'}"
	;
	
bool exists_bodyOf_removeNodeAndInlineValue(int n, int m, int j)  = true;
str generate_bodyOf_removeNodeAndInlineValue(int n, int m, int j) =
	"return <nodeOf(n-1, m+1, use(payloadTriple("mask") + generateSubnodeMembers(n) - subnodePair(j)))>;"
when m == 0;

default bool exists_bodyOf_removeNodeAndInlineValue(int n, int m, int j)  = true;
default str generate_bodyOf_removeNodeAndInlineValue(int n, int m, int j) =
	"<intercalate(" else ", [ "if (mask \< <keyPosName><i>) { return <nodeOf(n-1, m+1, use(insertBeforeOrDefaultAtEnd(generatePayloadMembers(m), payloadTriple(i), payloadTriple("mask")) + generateSubnodeMembers(n) - subnodePair(j)))>; }" | i <- [1..m+1] ])> else {
	'	return <nodeOf(n-1, m+1, use(generatePayloadMembers(m) + payloadTriple("mask") + generateSubnodeMembers(n) - subnodePair(j)))>;
	'}"
	;

str generateSpecializedNodeWithBitmapPositionsClassString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str classNamePostfix, int mn = tupleLength(ds)*m+n) {
	constructorArgs = ts.mutator + metadataArguments(ts) + contentArguments(n, m, ts, setup);

	extendsClassName = "<if (isOptionEnabled(setup,useUntypedVariables())) {><className_compactNode(ts, setup, true, true)><} else {><className_compactNode(ts, setup, n != 0, m != 0)><}>";

	return
	"private static final class <specializedClassName(n, m, ts)><GenericsStr(ts.tupleTypes)> extends <extendsClassName><GenericsStr(ts.tupleTypes)> {
	
	'	<intercalate("\n", mapper(contentArguments(n, m, ts, setup), str(Argument a) { 
			str dec = "private <dec(a)>;";
			
			if (field(_, /.*pos.*/) := a || getter(_, /.*pos.*/) := a) {
				return "\n<dec>";
			} else {
				return dec;
			} 
		}))>
			
	'	<specializedClassName(n, m, ts)>(<intercalate(", ", mapper(constructorArgs, str(Argument a) { return "<dec(a)>"; }))>) {					
	'		super(mutator, <use(bitmapField)>, <use(valmapField)>);
	'		<intercalate("\n", mapper(contentArguments(n, m, ts, setup), str(Argument a) { 
				str dec = "this.<use(a)> = <use(a)>;";
				
				if (field(_, /.*pos.*/) := a || getter(_, /.*pos.*/) := a) {
					return "\n<dec>";
				} else {
					return dec;
				} 
			}))>
	'		<if ((n + m) > 0) {>
	'		<}>assert nodeInvariant();
	'	}

	<if (false) {>	
	<if (\map() := ts.ds) {>
	'	@Override
	'	SupplierIterator<SupplierIteratorGenerics(ds)> payloadIterator() {
	'		<if (m > 0) {>return ArrayKeyValueSupplierIterator.of(new Object[] { <intercalate(", ", ["<keyName><i>, <valName><i>"  | i <- [1..m+1]])> });<} else {>return EmptySupplierIterator.emptyIterator();<}>
	'	}
	<} else {>
	'	@Override
	'	SupplierIterator<SupplierIteratorGenerics(ds)> payloadIterator() {
	'		<if (m > 0) {>return ArrayKeyValueSupplierIterator.of(new Object[] { <intercalate(", ", ["<keyName><i>, <keyName><i>"  | i <- [1..m+1]])> });<} else {>return EmptySupplierIterator.emptyIterator();<}>
	'	}	
	<}>
	<}>
	
	<implOrOverride(getDef(ts, trieNode(abstractNode()), hasSlots()), 
		generate_bodyOf_hasSlots(mn))>

	<implOrOverride(getDef(ts, trieNode(abstractNode()), slotArity()), 
		"return <mn>;")>

	<implOrOverride(getDef(ts, trieNode(abstractNode()), getSlot()),
		generate_bodyOf_getSlot(ts, mn))> 

	<if (isOptionEnabled(setup, useUntypedVariables())) {>

		<if (!isPrimitive(key(ts.keyType))) {><toString(UNCHECKED_ANNOTATION())><}>
		@Override
		<typeToString(ts.keyType)> getKey(int index) {
			return (<typeToString(ts.keyType)>) getSlot(<use(tupleLengthConstant)> * index);
		}
	
		<if (\map() := ts.ds) {>
		<if (!isPrimitive(val(ts.valType))) {><toString(UNCHECKED_ANNOTATION())><}>
		@Override
		<typeToString(ts.valType)> getValue(int index) {
			return (<typeToString(ts.valType)>) getSlot(<use(tupleLengthConstant)> * index + 1);
		}
		<}>

		<if (\map() := ts.ds) {>
		<toString(UNCHECKED_ANNOTATION())>
		@Override
		Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)> getKeyValueEntry(int index) {
			return entryOf((<typeToString(ts.keyType)>) getSlot(<use(tupleLengthConstant)> * index), (<typeToString(ts.valType)>) getSlot(<use(tupleLengthConstant)> * index + 1));
		}
		<}>

		<toString(UNCHECKED_ANNOTATION())>
		@Override
		public <CompactNode(ds)><GenericsStr(ts.tupleTypes)> getNode(int index) {
			final int offset = <use(tupleLengthConstant)> * payloadArity();
			return (<CompactNode(ds)><GenericsStr(ts.tupleTypes)>) getSlot(offset + index);
		}
		
		<toString(UNCHECKED_ANNOTATION())>
		@Override
		Iterator\<<CompactNode(ds)><GenericsStr(ts.tupleTypes)>\> nodeIterator() {
			final int offset = <use(tupleLengthConstant)> * payloadArity();
			final Object[] nodes = new Object[<mn> - offset];

			for (int i = 0; i \< <mn> - offset; i++) {
				// assert ((getSlot(offset + i) instanceof <AbstractNode(ds)>) == true);
				nodes[i] = getSlot(offset + i);
			}

			return (Iterator) ArrayIterator.of(nodes);
		}		
		
		@Override
		boolean hasNodes() {
			return <use(tupleLengthConstant)> * payloadArity() != <mn>;
		}

		@Override
		int nodeArity() {
			return <mn> - <use(tupleLengthConstant)> * payloadArity();
		}
		
		@Override
		boolean hasPayload() {
			return payloadArity() != 0;
		}

		@Override
		int payloadArity() {
			return <integerOrLongObject(bitPartitionSize)>.bitCount(<useSafeUnsigned(___valmapMethod(bitPartitionSize))>);
		}
		
		@Override
		byte sizePredicate() {
			if (this.nodeArity() == 0 && this.payloadArity() == 0) {
				return SIZE_EMPTY;
			} else if (this.nodeArity() == 0 && this.payloadArity() == 1) {
				return SIZE_ONE;
			} else {
				return SIZE_MORE_THAN_ONE;
			}
		}		
	<} else {>
	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> getNode(int index) {
	'		<generate_bodyOf_getNode(n)>
	'	}
	
	'	@Override
	'	<typeToString(ts.keyType)> getKey(int index) {
	'		<generate_bodyOf_getKey(m)>
	'	}

	<if (\map() := ts.ds) {>
	'	@Override
	'	<typeToString(ts.valType)> getValue(int index) {
	'		<generate_bodyOf_getValue(m)>
	'	}
	<}>
	
	<if (\map() := ts.ds) {>
	'	@Override
	'	Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)> getKeyValueEntry(int index) {
	'		<generate_bodyOf_getKeyValueEntry(ts, m)>
	'	}
	<}>	

	<if (false) {>	
	'	@Override
	'	Iterator\<<CompactNode(ds)><GenericsStr(ts.tupleTypes)>\> nodeIterator() {
	'		<if (n > 0) {>return ArrayIterator.of(<intercalate(", ", ["<nodeName><i>" | i <- [1..n+1]])>);<} else {>return Collections.\<<CompactNode(ds)><GenericsStr(ts.tupleTypes)>\>emptyIterator();<}>
	'	}
	<}>

	'	@Override
	'	boolean hasNodes() {
	'		return <if (n > 0) {>true<} else {>false<}>;
	'	}

	'	@Override
	'	int nodeArity() {
	'		return <n>;
	'	}
	
	'	@Override
	'	boolean hasPayload() {
	'		return <if (m > 0) {>true<} else {>false<}>;
	'	}

	'	@Override
	'	int payloadArity() {
	'		return <m>;
	'	}	
	
	'	@Override
	'	byte sizePredicate() {
	'		return <generate_bodyOf_sizePredicate(n, m, ts)>;
	'	}	
	<}>

	<if (\map() := ts.ds) {>
	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> copyAndSetValue(AtomicReference\<Thread\> mutator, <dec(ts.bitposField)>, <dec(val(ts.valType))>) {
	'		<generate_bodyOf_copyAndSetValue(n, m, ts, setup)>
	'	}
	<}>	
	
	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> copyAndInsertValue(AtomicReference\<Thread\> mutator, <dec(ts.bitposField)>, <dec(ts.payloadTuple)>) {		
	'		<generate_bodyOf_copyAndInsertValue(n, m, ts, setup)>
	'	}
	
	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> copyAndRemoveValue(AtomicReference\<Thread\> mutator, <dec(ts.bitposField)>) {
	'		<generate_bodyOf_copyAndRemoveValue(n, m, ts, setup)>
	'	}	

	'	@Override
	'	<CompactNode(ds)><GenericsStr(ts.tupleTypes)> copyAndSetNode(AtomicReference\<Thread\> mutator, <dec(ts.bitposField)>, <CompactNode(ds)><GenericsStr(ts.tupleTypes)> <nodeName>) {
	'		<generate_bodyOf_copyAndSetNode(n, m, ts, setup)>
	'	}	


	<implOrOverride(getDef(ts, trieNode(compactNode()), copyAndInsertNode()), 
		generate_bodyOf_copyAndInsertNode(n, m, ts, setup))>
	
	<implOrOverride(getDef(ts, trieNode(compactNode()), copyAndRemoveNode()),
		generate_bodyOf_copyAndRemoveNode(n, m, ts, setup))>	
	
	<implOrOverride(getDef(ts, trieNode(compactNode()), copyAndMigrateFromInlineToNode()),	
		generate_bodyOf_copyAndMigrateFromInlineToNode(n, m, ts, setup))>	
	
	<implOrOverride(getDef(ts, trieNode(compactNode()), copyAndMigrateFromNodeToInline()), 
		generate_bodyOf_copyAndMigrateFromNodeToInline(n, m, ts, setup))>
				
	<implOrOverride(getDef(ts, trieNode(compactNode()), hashCode()),				
		generate_bodyOf_hashCode(n, m, ts, setup))>	

	<implOrOverride(getDef(ts, trieNode(compactNode()), equals()), 	
	"		if (null == other) {
	'			return false;
	'		}
	'		if (this == other) {
	'			return true;
	'		}
	'		if (getClass() != other.getClass()) {
	'			return false;
	'		}
	'		<if ((n + m) > 0) {><specializedClassName(n, m, ts)><QuestionMarkGenerics(ts.ds, ts.tupleTypes)> that = (<specializedClassName(n, m, ts)><QuestionMarkGenerics(ts.ds, ts.tupleTypes)>) other;
	'
	'		<generate_equalityComparisons(n, m, ts, setup, equalityDefaultForArguments)><}>
	'
	'		return true;")>
		
	
	<generate_toString(n, m, ts, setup)>
		
	'}
	"
	;	
	
}

bool exists_bodyOf_hashCode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_bodyOf_hashCode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
"		<if ((n + m) > 0) {>final int prime = 31; int result = 1; result = prime * result + (<primitiveHashCode(___bitmapMethod(bitPartitionSize))>); result = prime * result + (<primitiveHashCode(___valmapMethod(bitPartitionSize))>);<} else {>int result = 1;<}>	
'		<for (i <- [0..mn]) {>result = prime * result + <hashCode(slot(i))>;<}>	
'		return result;"
when isOptionEnabled(setup,useUntypedVariables())	
	;

default bool exists_bodyOf_hashCode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
default str generate_bodyOf_hashCode(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) =
"		<if ((n + m) > 0) {>final int prime = 31; int result = 1; \n\n result = prime * result + (<primitiveHashCode(___bitmapMethod(bitPartitionSize))>); result = prime * result + (<primitiveHashCode(___valmapMethod(bitPartitionSize))>);<} else {>int result = 1;<}>
'	
'		<for (i <- [1..m+1]) {>		
'		result = prime * result + <hashCode(key(ts.keyType, i))>; <if (\map() := ts.ds) {>result = prime * result + <hashCode(val(ts.valType, i))>;<}> <}>
'		<for (i <- [1..n+1]) {>
'		result = prime * result + <hashCode(\node(ts.ds, ts.tupleTypes, i))>;<}>
'			
'		return result;"
;

bool exists_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
str generate_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
	""
	;

//bool exists_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) = true;
//str generate_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, int mn = tupleLength(ds)*m+n) =
//	""
//when isOptionEnabled(setup,useUntypedVariables())	
//	;
//
//default bool exists_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup)  = true;
//str generate_toString(int n, int m, ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup) =
//	"	@Override
//	'	public String toString() {		
//	'		<if (n == 0 && m == 0) {>return \"[]\";<} else {>return String.format(\"[<intercalate(", ", [ "@%d: %s<if (\map() := ts.ds) {>=%s<}>" | i <- [1..m+1] ] + [ "@%d: %s" | i <- [1..n+1] ])>]\", <use([ field("recoverMask(<use(valmapMethod)>, (byte) <i>)"), *__payloadTuple(ts.ds, ts.tupleTypes, i) | i <- [1..m+1]] + [ field("recoverMask(<use(bitmapMethod)>, (byte) <i>)"), \node(ts.ds, ts.tupleTypes, i)	| i <- [1..n+1]])>);<}>
//	'	}";

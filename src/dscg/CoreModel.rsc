/**
 * Copyright (c) 2015 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
 */
module dscg::CoreModel

import dscg::Common;
import dscg::Common_ContentType;

import IO;
import List;
import util::Math;
import util::Maybe;



int maxUntypedSlotArityCount(TrieSpecifics ts)
	= tupleLength(ts.ds) * ts.nMax 
when isOptionEnabled(ts.setup, useHeterogeneousEncoding());

Maybe[int] maxUntypedSlotArityCount(list[Partition] partitionList) 
	= nothing()
when /Partition x := partitionList, x.range == unbounded();

Maybe[int] maxUntypedSlotArityCount(list[Partition] partitionList) { 
	for([ *_, Partition x, *_ ] := partitionList) {
		println(x.range);
		println(size(x));
	}

	return just(1);	
}




data RangeStrategy 
	= rsShare()
	| rsConcat();

int size(Range r) 
	= size([r.lower, r.lower + r.stride .. r.upper + extension])
when extension := (r.isUpperIncluded ? 1 : 0);

// TODO: traverse recursively and perform different calculations based on function (with / without scaling) 
// TODO: distinct base case (slice) and calculated attribute (strip)
int logicalSize(Partition p) 
	= size(p.range)
when p is slice;

int logicalSize(Partition p) 
	= 0 // TODO
when p is strip;
	
int physicalSize(Partition p) 
	= size(scaleLowerAndUpper(p.range, arity(p.itemType)))
when p is slice;

int physicalSize(Partition p) 
	= 0 // TODO
when p is strip;

Range scaleLowerAndUpper(Range r:range(lower, upper, isUpperIncluded, stride), int factor) 
	= range(lower * factor, upper * factor, isUpperIncluded, stride);
	
Range widenLowerAndUpper(Range r1:range(lower1, upper1, bool isUpperIncluded, int stride), Range r2:range(lower2, upper2, isUpperIncluded, stride)) 
	= range(min(lower1, lower2), max(upper1, upper2), isUpperIncluded, stride);	

Range widenLowerAndUpper(Range::unbounded(), Range::unbounded()) = Range::unbounded();

default Range widenLowerAndUpper(Range r1, Range r2) { throw "Cannot merge ranges if `isUpperIncluded` or `stride` differ.\n\n<r1>\n\n<r2>"; }

int arity(Type::typeSequence(list[Type] typeArguments)) = size(typeArguments);
default int arity(Type _) = 1;



/*
	specializedBitmapIndexedNode(mn, m)) | m <- [0..ts.nMax+1], mn <- [0..tupleLength(ts.ds) * (ts.nMax - m)  + 1], (m + mn/2) <= ts.nBound ]
	
	int heterogeneousBound = tupleLength(ts.ds) * ts.nBound;
*/

data Direction 
	= forward()
	| backward()
	| mixed(); // offset, heap/stack

// TODO: create 'either' type
// TODO: create 'strategies' for merging slices (e.g., based on IDs)
data Partition
	= slice(str id, ContentType contentType, Type itemType, Range range = unbounded(), Direction direction = forward())
	| strip(str id, ContentType contentType, Type itemType, Direction direction, list[Partition] sliceList, Range range = unbounded());
	
data Range
	= unbounded()
	| range(int lower, int upper, bool isUpperIncluded, int stride);
	
Range rangeFromToInclusive(int lower, int upper) = range(lower, upper, true, 1);
	
/*
	Example:
		slice("payload", ctPayloadTuple(), [ primitive("int"), primitive("int") ])
	
	typedPayload | typedNodes
	untypedPayload | untypedNodes
	[...]	
	typedPayload | typedRarePayload | typedNodes			pp(simplify(pscene_untypedPayload_untypedRarePayload_untypedNodes(), psStrip({ "payload", "node" })))
	typedPayload | untypedRarePayload | untypedNodes
	untypedPayload | untypedRarePayload | untypedNodes	
*/	

//str pp(list[Partition] partitionList) = ( "" | it + pp(e) | e <- partitionList );
//str pp(list[Partition] partitionList) = toString([ pp(e) | e <- partitionList ]); 
str pp(list[Partition] partitionList) = intercalate(" ++ ", [ pp(e) | e <- partitionList ]);

str pp(Partition::slice(str id, ContentType contentType, Type itemType)) 
	= "slice(<id>)"; 

str pp(Partition::strip(str _, ContentType contentType, Type itemType, Direction direction, list[Partition] sliceList)) 
	= "strip(<id>)"
when id := intercalate("+", [ e.id | e <- sliceList ]); 
	
data PartitionStrategy
	= psStrip(set[str] idSet)
	| psStripIfReferenceType();
	// TODO: add boxing strategy
	// TODO: add strategy to disect either types
	


list[Partition] pscene_typedPayload_typedNodes_bounded() = [
		slice("payload", ctPayloadTuple(isRare = false), typeSequence([ primitive("int"), primitive("int") ]), range = rangeFromToInclusive(0, 32)),
		slice("node", ctNode(), specific("Node"), direction = backward(), range = rangeFromToInclusive(0, 32))
	];

list[Partition] pscene_typedPayload_typedRarePayload_typedNodes_bounded() = [
		slice("payload", ctPayloadTuple(isRare = false), typeSequence([ primitive("int"), primitive("int") ]), range = rangeFromToInclusive(0, 32)),
		slice("rarePayload", ctPayloadTuple(isRare = true), typeSequence([ generic("K"), generic("V") ]), range = rangeFromToInclusive(0, 32)),		
		slice("node", ctNode(), specific("Node"), direction = backward(), range = rangeFromToInclusive(0, 32))
	];

list[Partition] pscene_typedPayload_typedRarePayload_typedNodes_bounded_simplifyWith_psStripIfReferenceType() = 
	simplify(pscene_typedPayload_typedRarePayload_typedNodes_bounded(), psStripIfReferenceType());	

		
	
list[Partition] pscene_typedPayload_typedNodes() = [
		slice("payload", ctPayloadTuple(isRare = false), typeSequence([ primitive("int"), primitive("int") ])),
		slice("node", ctNode(), specific("Node"), direction = backward())
	];

test bool test_pp_pscene_typedPayload_typedNodes() = 
	pp(pscene_typedPayload_typedNodes()) == "slice(payload) ++ slice(node)";
	
test bool test_pp_pscene_typedPayload_typedNodes_simplifyWith_psStrip() = 
	pp(simplify(pscene_typedPayload_typedNodes(), psStrip({ "payload", "node" }))) == "strip(payload+node)";
	
// no simplification happens
test bool test_pp_pscene_typedPayload_typedNodes_simplifyWith_psStripIfReferenceType() = 
	pp(simplify(pscene_typedPayload_typedNodes(), psStripIfReferenceType())) == "slice(payload) ++ slice(node)";			



	
list[Partition] pscene_typedPayload_typedRarePayload_typedNodes() = [
		slice("payload", ctPayloadTuple(isRare = false), typeSequence([ primitive("int"), primitive("int") ])),
		slice("rarePayload", ctPayloadTuple(isRare = true), typeSequence([ generic("K"), generic("V") ])),		
		slice("node", ctNode(), specific("Node"), direction = backward())
	];
	
// no simplification happens 
test bool test_pp_pscene_pscene_typedPayload_typedRarePayload_typedNodes_simplifyWith_psStrip() =
	pp(simplify(pscene_typedPayload_typedRarePayload_typedNodes(), psStrip({ "payload", "node" }))) == "slice(payload) ++ slice(rarePayload) ++ slice(node)";
	
test bool test_pp_pscene_pscene_typedPayload_typedRarePayload_typedNodes_simplifyWith_psStripIfReferenceType() = 
	pp(simplify(pscene_typedPayload_typedRarePayload_typedNodes(), psStripIfReferenceType())) == "slice(payload) ++ strip(rarePayload+node)";	
		
			
	
// Partition mkStrip(Partition::slice p1, Partition p2)
Partition mkStrip(Partition p1, Partition p2)
	= strip(id, contentType, itemType, direction, [ p1, p2 ], range = range)
when p1 is slice && p2 is slice && 
		id := "<p1.id>+<p2.id>" &&
		contentType := mkStripContentType(p1.contentType, p2.contentType) &&
		itemType := mkStripType(p1.itemType, p2.itemType) &&
		direction := mkStripDirection(p1.direction, p2.direction) &&
		range := mkStripRange(p1.range, p2.range);
			
Partition mkStrip(
			p1:Partition::strip(str _, ContentType _, Type _, Direction _, list[Partition] _), 
			p2:Partition::slice(str _, ContentType _, Type _))
	= strip(id, contentType, itemType, direction, [ *p1.sliceList, p2 ], range = range)
when id := "<p1.id>+<p2.id>" &&
		itemType := mkStripType(p1.itemType, p2.itemType) &&
		contentType := mkStripContentType(p1.contentType, p2.contentType) &&
		direction := mkStripDirection(p1.direction, p2.direction) && 
		range := mkStripRange(p1.range, p2.range);		
	
Partition mkStrip(Partition p1, Partition p2) = mkStrip(p2, p1) when p1 is slice && p2 is partition;

default Partition mkStrip(Partition p1, Partition p2) { print(
 	"<pp(p1)>
	'<pp(p2)>
	'<p1>
	'<p2>");
	
	throw "Ahhh";
}
	
/* calculates the joint Java type (without widening support for primitives) */ 
Type mkStripType(Type t, t) = t;
default Type mkStripType(Type _, Type _) = object();

ContentType mkStripContentType(ContentType ct, ct) = ct;
default ContentType mkStripContentType(ContentType _, ContentType _) = ContentType::ctSlot();
		
Direction mkStripDirection(Direction::forward(), Direction::forward()) = Direction::forward();
Direction mkStripDirection(Direction::forward(), Direction::backward()) = Direction::mixed();
Direction mkStripDirection(Direction::backward(), Direction::forward()) = Direction::mixed(); 
Direction mkStripDirection(Direction::backward(), Direction::backward()) = Direction::backward();

Range mkStripRange(Range::unbound(), Range _) = Range::unbound();
Range mkStripRange(Range _, Range::unbound()) = Range::unbound();
Range mkStripRange(Range r1, Range r2) = widenLowerAndUpper(r1, r2);




list[Partition] simplify(list[Partition] partitionList) = simplify(partitionList, {}); 

list[Partition] simplify(list[Partition] partitionList, PartitionStrategy strategy) = simplify(partitionList, { strategy }); 
	
list[Partition] simplify(list[Partition] partitionList, set[PartitionStrategy] strategySet) {
	simplifiedPartitionList = partitionList;
	
	solve(simplifiedPartitionList) {
		simplifiedPartitionList = simplifyOne(simplifiedPartitionList, strategySet);
	}
	
	return simplifiedPartitionList;
}


	
list[Partition] simplifyOne(list[Partition] partitionList:[ *front, p1, p2, *back ], set[PartitionStrategy] strategySet) 
	= [ *front, mkStrip(p1, p2), *back ]
when id1 := p1.id && id2 := p2.id && 
		/strategy:psStrip(idSet:{ id1, id2, *_ }) := strategySet;
		
list[Partition] simplifyOne(list[Partition] partitionList:[ *front, p1, p2, *back ], set[PartitionStrategy] strategySet) 
	= [ *front, mkStrip(p1, p2), *back ]
when isReference(p1.itemType) && isReference(p2.itemType) && 
		/strategy:psStripIfReferenceType() := strategySet;								
		
default list[Partition] simplifyOne(list[Partition] partitionList, set[PartitionStrategy] strategySet) = partitionList;



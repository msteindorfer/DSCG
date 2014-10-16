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
module dscg::GenerateTrie_Core

import List;
import String;
import dscg::Common;
import dscg::GenerateTrie_Core_Common;

str generateCoreClassString(ts:___expandedTrieSpecifics(ds, bitPartitionSize, nMax, nBound), rel[Option,bool] setup, str innerClassesString) {
	
	str emptyCollectionConstantName = "EMPTY_<toUpperCase(toString(ts.ds))>";
	str emptyTrieNodeConstantName   = "EMPTY_NODE";
	
return 
"/*******************************************************************************
 * Copyright (c) 2013-2014 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
 *******************************************************************************/
package org.eclipse.imp.pdb.facts.util;

import static org.eclipse.imp.pdb.facts.util.AbstractSpecialisedImmutableMap.entryOf;

import java.text.DecimalFormat;
import java.util.AbstractMap;
import java.util.AbstractSet;
import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.Deque;
import java.util.Iterator;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

@SuppressWarnings(\"rawtypes\")
public class <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)> extends Abstract<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> implements Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> {

	<toString(UNCHECKED_ANNOTATION())>
	private static final <ts.coreClassName> <emptyCollectionConstantName> = new <ts.coreClassName>(Compact<toString(ts.ds)>Node.<emptyTrieNodeConstantName>, 0, 0);

	private static final boolean DEBUG = false;

	private final <AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> rootNode;
	private final int hashCode;
	private final int cachedSize;

	<ts.coreClassName>(<AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> rootNode, int hashCode, int cachedSize) {
		this.rootNode = rootNode;
		this.hashCode = hashCode;
		this.cachedSize = cachedSize;
		if (DEBUG) {
			assert checkHashCodeAndSize(hashCode, cachedSize);
		}
	}

	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> of() {
		return <ts.coreClassName>.<emptyCollectionConstantName>;
	}

	<if (ds == \map()) {>
	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> of(Object... keyValuePairs) {
		if (keyValuePairs.length % 2 != 0) {
			throw new IllegalArgumentException(\"Length of argument list is uneven: no key/value pairs.\");
		}

		Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> result = <ts.coreClassName>.<emptyCollectionConstantName>;

		for (int i = 0; i \< keyValuePairs.length; i += 2) {
			<dec(key(ts.keyType))> = (<toString(ts.keyType)>) keyValuePairs[i];
			<dec(val(ts.valType))> = (<toString(ts.valType)>) keyValuePairs[i + 1];

			result = result.<insertOrPutMethodName(ts.ds)>(<use(ts.payloadTuple)>);
		}

		return result;
	}
	<}>
	
	<if (ds == \set()) {>
	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> of(<toString(ts.keyType)>... keys) {
		Immutable<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> result = <ts.coreClassName>.<emptyCollectionConstantName>;

		for (<dec(key(ts.keyType))> : keys) {
			result = result.<insertOrPutMethodName(ts.ds)>(<use(key(ts.keyType))>);
		}

		return result;
	}
	<}>
	
	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> transientOf() {
		return <ts.coreClassName>.<emptyCollectionConstantName>.asTransient();
	}

	<if (ds == \map()) {>
	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> transientOf(Object... keyValuePairs) {
		if (keyValuePairs.length % 2 != 0) {
			throw new IllegalArgumentException(
							\"Length of argument list is uneven: no key/value pairs.\");
		}

		final Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> result = <ts.coreClassName>.<emptyCollectionConstantName>.asTransient();

		for (int i = 0; i \< keyValuePairs.length; i += 2) {
			<dec(key(ts.keyType))> = (<toString(ts.keyType)>) keyValuePairs[i];
			<dec(val(ts.valType))> = (<toString(ts.valType)>) keyValuePairs[i + 1];

			result.<insertOrPutMethodName(ts.ds)>(<use(ts.payloadTuple)>);
		}

		return result;
	}
	<}>
	
	<if (ds == \set()) {>
	<toString(UNCHECKED_ANNOTATION())>
	public static final <Generics(ts.ds, ts.tupleTypes)> Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> transientOf(<toString(ts.keyType)>... keys) {
		final Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> result = <ts.coreClassName>.<emptyCollectionConstantName>.asTransient();

		for (<dec(key(ts.keyType))> : keys) {
			result.<insertOrPutMethodName(ts.ds)>(<use(key(ts.keyType))>);
		}

		return result;
	}
	<}>

	<generate_checkHashCodeAndSize(ts, setup)>
	
	<implOrOverride(ts.Core_updated, 		generate_bodyOf_Core_updated(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_updatedEquiv,	generate_bodyOf_Core_updated(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_removed, 		generate_bodyOf_Core_removed(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_removedEquiv,	generate_bodyOf_Core_removed(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_containsKey, 		generate_bodyOf_Core_containsKey(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_containsKeyEquiv,	generate_bodyOf_Core_containsKey(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_containsValue, 		generate_bodyOf_Core_containsValue(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_containsValueEquiv,	generate_bodyOf_Core_containsValue(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_get, 		generate_bodyOf_Core_get(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_getEquiv,	generate_bodyOf_Core_get(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_insertOrPutAll, 		generate_bodyOf_Core_insertOrPutAll(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_insertOrPutAllEquiv,	generate_bodyOf_Core_insertOrPutAll(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_retainAll, 		generate_bodyOf_Core_retainAll(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_retainAllEquiv,	generate_bodyOf_Core_retainAll(ts, setup, equalityComparatorForArguments	))>

	<implOrOverride(ts.Core_removeAll, 		generate_bodyOf_Core_removeAll(ts, setup, equalityDefaultForArguments		))>
	<implOrOverride(ts.Core_removeAllEquiv,	generate_bodyOf_Core_removeAll(ts, setup, equalityComparatorForArguments	))>



	<implOrOverride(ts.jul_Map_put, UNSUPPORTED_OPERATION_EXCEPTION)>	
	<implOrOverride(ts.jul_Map_clear, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Map_remove, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Map_putAll, UNSUPPORTED_OPERATION_EXCEPTION)>
	
	<implOrOverride(ts.jul_Set_add, UNSUPPORTED_OPERATION_EXCEPTION)>	
	<implOrOverride(ts.jul_Set_clear, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Set_remove, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Set_addAll, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Set_removeAll, UNSUPPORTED_OPERATION_EXCEPTION)>
	<implOrOverride(ts.jul_Set_retainAll, UNSUPPORTED_OPERATION_EXCEPTION)>

	<implOrOverride(ts.jul_Set_containsAll, 	
		"for (Object item : c) {
			if (!contains(item)) {
				return false;
			}
		}
		return true;")>

	<implOrOverride(ts.jul_Set_containsAllEquivalent,	
		"for (Object item : c) {
			if (!containsEquivalent(item, cmp)) {
				return false;
			}
		}
		return true;")>

	@Override
	public int size() {
		return cachedSize;
	}

	<if (ds == \set()) {>
	@Override
	public Iterator<GenericsExpanded(ts.ds, ts.tupleTypes)> iterator() {
		return keyIterator();
	}
	<}>

	@Override
	public SupplierIterator<SupplierIteratorGenerics(ts.ds, ts.tupleTypes)> keyIterator() {
		<generate_bodyOf_keyIterator(ts, ts.setup)>
	}

	<if (ds == \map()) {>
	@Override
	public Iterator\<<toString(primitiveToClass(ts.valType))>\> valueIterator() {
		return new <toString(ts.ds)>ValueIterator<InferredGenerics(ts.ds, ts.tupleTypes)>(rootNode);
	}

	@Override
	public Iterator\<Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\> entryIterator() {
		return new <toString(ts.ds)>EntryIterator<InferredGenerics(ts.ds, ts.tupleTypes)>(rootNode);
	}
	<}>

	<if (ds == \map()) {>
	@Override
	public Set\<java.util.Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\> entrySet() {
		Set\<java.util.Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\> entrySet = null;

		if (entrySet == null) {
			entrySet = new AbstractSet\<java.util.Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\>() {
				@Override
				public Iterator\<java.util.Map.Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\> iterator() {
					return new Iterator\<Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\>() {
						private final Iterator\<Entry<GenericsExpanded(ts.ds, ts.tupleTypes)>\> i = entryIterator();

						@Override
						public boolean hasNext() {
							return i.hasNext();
						}

						@Override
						public Entry<GenericsExpanded(ts.ds, ts.tupleTypes)> next() {
							return i.next();
						}

						@Override
						public void remove() {
							i.remove();
						}
					};
				}

				@Override
				public int size() {
					return <ts.coreClassName>.this.size();
				}

				@Override
				public boolean isEmpty() {
					return <ts.coreClassName>.this.isEmpty();
				}

				@Override
				public void clear() {
					<ts.coreClassName>.this.clear();
				}

				@Override
				public boolean contains(Object k) {
					return <ts.coreClassName>.this.containsKey(k);
				}
			};
		}
		return entrySet;
	}
	<}>

	@Override
	public boolean isTransientSupported() {
		return true;
	}

	@Override
	public Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> asTransient() {
		return new Transient<ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(this);
	}

	@Override
	public int hashCode() {
		return hashCode;
	}

	<if (isOptionEnabled(setup, useStructuralEquality())) {>
	@Override
	public boolean equals(Object other) {
		if (other == this) {
			return true;
		}
		if (other == null) {
			return false;
		}

		if (other instanceof <ts.coreClassName>) {
			<ts.coreClassName><QuestionMarkGenerics(ts.ds, ts.tupleTypes)> that = (<ts.coreClassName><QuestionMarkGenerics(ts.ds, ts.tupleTypes)>) other;

			if (this.size() != that.size()) {
				return false;
			}

			return rootNode.equals(that.rootNode);
		}

		return super.equals(other);
	}
	<}>

	/*
	 * For analysis purposes only.
	 */
	protected <AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> getRootNode() {
		return rootNode;
	}

	/*
	 * For analysis purposes only.
	 */
	protected Iterator\<<AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)>\> nodeIterator() {
		return new <ts.nodeIteratorClassName><InferredGenerics(ts.ds, ts.tupleTypes)>(rootNode);
	}

	/*
	 * For analysis purposes only.
	 */
	protected int getNodeCount() {
		final Iterator\<<AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)>\> it = nodeIterator();
		int sumNodes = 0;

		for (; it.hasNext(); it.next()) {
			sumNodes += 1;
		}

		return sumNodes;
	}

	/*
	 * For analysis purposes only. Payload X Node
	 */
	protected int[][] arityCombinationsHistogram() {
		final Iterator\<<AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)>\> it = nodeIterator();
		final int[][] sumArityCombinations = new int[<nMax+1>][<nMax+1>];

		while (it.hasNext()) {
			final <AbstractNode(ts.ds)><Generics(ts.ds, ts.tupleTypes)> node = it.next();
			sumArityCombinations[node.payloadArity()][node.nodeArity()] += 1;
		}

		return sumArityCombinations;
	}

	/*
	 * For analysis purposes only.
	 */
	protected int[] arityHistogram() {
		final int[][] sumArityCombinations = arityCombinationsHistogram();
		final int[] sumArity = new int[<nMax+1>];

		final int maxArity = <nMax>; // TODO: factor out constant

		for (int j = 0; j \<= maxArity; j++) {
			for (int maxRestArity = maxArity - j, k = 0; k \<= maxRestArity - j; k++) {
				sumArity[j + k] += sumArityCombinations[j][k];
			}
		}

		return sumArity;
	}

	/*
	 * For analysis purposes only.
	 */
	public void printStatistics() {
		final int[][] sumArityCombinations = arityCombinationsHistogram();
		final int[] sumArity = arityHistogram();
		final int sumNodes = getNodeCount();

		final int[] cumsumArity = new int[<nMax+1>];
		for (int cumsum = 0, i = 0; i \< <nMax+1>; i++) {
			cumsum += sumArity[i];
			cumsumArity[i] = cumsum;
		}

		final float threshhold = 0.01f; // for printing results
		for (int i = 0; i \< <nMax+1>; i++) {
			float arityPercentage = (float) (sumArity[i]) / sumNodes;
			float cumsumArityPercentage = (float) (cumsumArity[i]) / sumNodes;

			if (arityPercentage != 0 && arityPercentage \>= threshhold) {
				// details per level
				StringBuilder bldr = new StringBuilder();
				int max = i;
				for (int j = 0; j \<= max; j++) {
					for (int k = max - j; k \<= max - j; k++) {
						float arityCombinationsPercentage = (float) (sumArityCombinations[j][k])
										/ sumNodes;

						if (arityCombinationsPercentage != 0
										&& arityCombinationsPercentage \>= threshhold) {
							bldr.append(String.format(\"%d/%d: %s, \", j, k, new DecimalFormat(
											\"0.00%\").format(arityCombinationsPercentage)));
						}
					}
				}
				final String detailPercentages = bldr.toString();

				// overview
				System.out.println(String.format(\"%2d: %s\\t[cumsum = %s]\\t%s\", i,
								new DecimalFormat(\"0.00%\").format(arityPercentage),
								new DecimalFormat(\"0.00%\").format(cumsumArityPercentage),
								detailPercentages));
			}
		}
	}
	
	<innerClassesString>
		
}";
}

str generate_bodyOf_keyIterator(TrieSpecifics ts, rel[Option,bool] setup:{_*, <useFixedStackIterator(),true>}) = 
	"return new <toString(ts.ds)>KeyIterator<InferredGenerics(ts.ds, ts.tupleTypes)>(rootNode);"
	;
	
default str generate_bodyOf_keyIterator(TrieSpecifics ts, rel[Option,bool] setup) =
	"return new <ts.coreClassName>Iterator<InferredGenerics(ts.ds, ts.tupleTypes)>((Compact<toString(ts.ds)>Node<Generics(ts.ds, ts.tupleTypes)>) rootNode);"
	;
	
	
default str generate_bodyOf_Core_updated(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq) {

	str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>";

	return  
	"	final int keyHash = key.hashCode();
		<dec(ts.details)> = Result.unchanged();
		
		<dec(\node(ts.ds, ts.tupleTypes, "newRootNode"))> = rootNode.updated(null, <use(ts.payloadTuple)>, keyHash, 0, <use(ts.details)><optionalComparatorArgument>);

		if (<use(ts.details)>.isModified()) {
			<if (ts.ds == \map()) {>
				if (<use(ts.details)>.hasReplacedValue()) {
					final int valHashOld = <hashCode(val(ts.valType, "<use(ts.details)>.getReplacedValue()"))>;
					final int valHashNew = <hashCode(val(ts.valType))>;
	
					return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + (keyHash ^ valHashNew)
									- (keyHash ^ valHashOld), cachedSize);
				}
			<}>
				
			<if (ts.ds == \map()) {>
				final int valHash = <hashCode(val(ts.valType))>;
				return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + (keyHash ^ valHash), cachedSize + 1);
			<} else {>
				return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode + keyHash, cachedSize + 1);			
			<}>
		}

		return this;"
	;
}

default str generate_bodyOf_Core_removed(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq, 
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>") =
	"final int keyHash = key.hashCode();
	<dec(ts.details)> = Result.unchanged();
	
	<dec(\node(ts.ds, ts.tupleTypes, "newRootNode"))> = rootNode.removed(null, key, keyHash, 0, <use(ts.details)><optionalComparatorArgument>);

	if (<use(ts.details)>.isModified()) {
		<if (ts.ds == \set()) {>
			return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode - keyHash, cachedSize - 1);
		<} else {>
			assert <use(ts.details)>.hasReplacedValue();
			final int valHash = <hashCode(val(ts.valType, "<use(ts.details)>.getReplacedValue()"))>;

			return new <ts.coreClassName><Generics(ts.ds, ts.tupleTypes)>(newRootNode, hashCode - (keyHash ^ valHash), cachedSize - 1);
		<}>
	}

	return this;"
	;

default str generate_bodyOf_Core_containsKey(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>") =
	"try {
		<toString(UNCHECKED_ANNOTATION())>
		<dec(key(ts.keyType))> = (<toString(ts.keyType)>) o;
		return rootNode.containsKey(<use(key(ts.keyType))>, <hashCode(key(ts.keyType))>, 0<optionalComparatorArgument>);			
	} catch (ClassCastException unused) {
		return false;
	}"
	;

default str generate_bodyOf_Core_containsValue(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>") =
	"	for (Iterator\<<toString(primitiveToClass(ts.valType))>\> iterator = valueIterator(); iterator.hasNext();) {
			if (iterator.next().equals(o)) {
				return true;
			}
		}
		return false;"
	;

default str generate_bodyOf_Core_get(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>") =
	"	try {
			<toString(UNCHECKED_ANNOTATION())>
			<dec(key(ts.keyType))> = (<toString(ts.keyType)>) o;
			final Optional<MapsToGenerics(ts.ds, ts.tupleTypes)> result = rootNode.findByKey(<use(key(ts.keyType))>, <hashCode(key(ts.keyType))>, 0<optionalComparatorArgument>);
	
			if (result.isPresent()) {
				return result.get();
			} else {
				return null;
			}			
		} catch (ClassCastException unused) {
			return null;
		}"
	;	
	
default str generate_bodyOf_Core_insertOrPutAll(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>",
				str optionalEquivalentPostfix = "<if (!(eq == equalityDefaultForArguments)) {>Equivalent<}>") =

	"	Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> tmp = asTransient();
		tmp.<insertOrPutMethodName(ts.ds)>All<optionalEquivalentPostfix>(<uncapitalize(toString(ts.ds))><optionalComparatorArgument>);
		return tmp.freeze();"
	;		

default str generate_bodyOf_Core_retainAll(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>",
				str optionalEquivalentPostfix = "<if (!(eq == equalityDefaultForArguments)) {>Equivalent<}>") =

	"	Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> tmp = asTransient();
		tmp.__retainAll<optionalEquivalentPostfix>(<uncapitalize(toString(ts.ds))><optionalComparatorArgument>);
		return tmp.freeze();"
	;		

default str generate_bodyOf_Core_removeAll(TrieSpecifics ts, rel[Option,bool] setup, str(Argument, Argument) eq,
				str optionalComparatorArgument = "<if (!(eq == equalityDefaultForArguments)) {>, <cmpName><}>",
				str optionalEquivalentPostfix = "<if (!(eq == equalityDefaultForArguments)) {>Equivalent<}>") =

	"	Transient<toString(ts.ds)><GenericsExpanded(ts.ds, ts.tupleTypes)> tmp = asTransient();
		tmp.__removeAll<optionalEquivalentPostfix>(<uncapitalize(toString(ts.ds))><optionalComparatorArgument>);
		return tmp.freeze();"
	;		

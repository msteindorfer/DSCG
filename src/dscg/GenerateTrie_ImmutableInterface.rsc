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
module dscg::GenerateTrie_ImmutableInterface

import dscg::Common;
import dscg::GenerateTrie;
import dscg::GenerateTrie_Core_Common;

str copyrightHeaderWithPackageAndImports = 
"/*******************************************************************************
 * Copyright (c) 2013-2015 CWI
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *   * Michael Steindorfer - Michael.Steindorfer@cwi.nl - CWI  
 *******************************************************************************/
package <targetBasePackage>;

import java.util.Comparator;
import java.util.Iterator;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.function.BiFunction;";

str generateImmutableInterface(TrieSpecifics ts) =
"<copyrightHeaderWithPackageAndImports>

public interface <immutableInterfaceName(ts.ds)><ts.GenericsStr> extends <toString(ts.ds)><ts.GenericsStr> {

	<generate_bodyOf_ImmutableInterface(ts)>
		
}";

str generate_bodyOf_ImmutableInterface(TrieSpecifics ts) = 
"
	<dec(ts.jul_Set_containsAll)>
	<dec(ts.jul_Set_containsAllEquivalent)>

	<dec(ts.Core_get)>
	<dec(ts.Core_getEquiv)>

	<dec(getDef(setArtifact(ts, core(immutable())), containsKey()))>
	<dec(getDef(setArtifact(ts, core(immutable())), containsKey(customComparator = true)))>

	<dec(getDef(setArtifact(ts, core(immutable())), containsValue()))>
	<dec(getDef(setArtifact(ts, core(immutable())), containsValue(customComparator = true)))>

	<dec(getDef(setArtifact(ts, core(immutable())), containsEntry()))>
	<dec(getDef(setArtifact(ts, core(immutable())), containsEntry(customComparator = true)))>

	<dec(getDef(setArtifact(ts, core(immutable())), insertTuple()))>
	<dec(getDef(setArtifact(ts, core(immutable())), insertTuple(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(immutable())), insertCollection()))>
	<dec(getDef(setArtifact(ts, core(immutable())), insertCollection(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(immutable())), removeTuple()))>
	<dec(getDef(setArtifact(ts, core(immutable())), removeTuple(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(immutable())), removeCollection()))>
	<dec(getDef(setArtifact(ts, core(immutable())), removeCollection(customComparator = true)))>

	<dec(ts.Core_retainAll)>
	<dec(ts.Core_retainAllEquiv)>
	
	<dec(ts.Core_keyIterator)>
	<dec(getDef(setArtifact(ts, core(immutable())), valueIterator()))>
	<dec(getDef(setArtifact(ts, core(immutable())), entryIterator()))>
	<dec(getDef(setArtifact(ts, core(immutable())), tupleIterator()))>
	
	<dec(getDef(setArtifact(ts, core(immutable())), isTransientSupported()))>
	<dec(getDef(setArtifact(ts, core(immutable())), asTransient()))>
";

str generateTransientInterface(TrieSpecifics ts) =
"<copyrightHeaderWithPackageAndImports>

public interface <transientInterfaceName(ts.ds)><ts.GenericsStr> extends <toString(ts.ds)><ts.GenericsStr> {

	<generate_bodyOf_TransientInterface(ts)>
		
}";

str generate_bodyOf_TransientInterface(TrieSpecifics ts) = 
"
	<dec(ts.jul_Set_containsAll)>
	<dec(ts.jul_Set_containsAllEquivalent)>

	<dec(ts.Core_get)>
	<dec(ts.Core_getEquiv)>

	<dec(getDef(setArtifact(ts, core(transient())), containsKey()))>
	<dec(getDef(setArtifact(ts, core(transient())), containsKey(customComparator = true)))>

	<dec(getDef(setArtifact(ts, core(transient())), containsValue()))>
	<dec(getDef(setArtifact(ts, core(transient())), containsValue(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(transient())), containsEntry()))>
	<dec(getDef(setArtifact(ts, core(transient())), containsEntry(customComparator = true)))>	
	
	<dec(getDef(setArtifact(ts, core(transient())), insertTuple()))>
	<dec(getDef(setArtifact(ts, core(transient())), insertTuple(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(transient())), insertCollection()))>
	<dec(getDef(setArtifact(ts, core(transient())), insertCollection(customComparator = true)))>

	<dec(getDef(setArtifact(ts, core(transient())), removeTuple()))>
	<dec(getDef(setArtifact(ts, core(transient())), removeTuple(customComparator = true)))>
	
	<dec(getDef(setArtifact(ts, core(transient())), removeCollection()))>
	<dec(getDef(setArtifact(ts, core(transient())), removeCollection(customComparator = true)))>

	<dec(ts.CoreTransient_retainAll)>
	<dec(ts.CoreTransient_retainAllEquiv)>
	
	<dec(ts.Core_keyIterator)>
	<dec(getDef(setArtifact(ts, core(transient())), valueIterator()))>
	<dec(getDef(setArtifact(ts, core(transient())), entryIterator()))>
	<dec(getDef(setArtifact(ts, core(transient())), tupleIterator()))>
		
	<dec(getDef(setArtifact(ts, core(transient())), freeze()))>
";
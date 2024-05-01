/**
 * Esperandieu Elbon II - 07/29/2023
 * COP 3503 - Computer Science II - Prof. Matthew Gerber
 * Final Project - Skip List Set
 * Custom Java Sorted Set Collection Running off the back of a Skip List Structure
 */

// Imports
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.SortedSet;
import java.util.SplittableRandom;

// Skip List based Set
public class SkipListSet<T extends Comparable<T>> implements SortedSet<T>  {

    // Attributes 
    private Node head;                              // Head node of the linked list the skipList is built on
    private Node tail;                              // Tail node of the linked list the SkipList is built on
    private int currLevel;                          // Current max height of the SkipList
    private int size;                               // Current number of elements stored in the skipList
    private int absoluteMaxLevel;                   // Absolute Maximum height of the SkipList 
    private int absoluteMinLevel;                   // Absolute Minimum height of the SkipList

    // Randomizer
    private static SplittableRandom levelRandomizer;

    // Item Wrapper Class to store Generic Elements and to build the SkipList off of
    private class Node {

        // Attributes
        private T element;                          // Element being stored in Node
        private int level;                          // Individual level of the Node
        private ArrayList<Node> nextNodes;          // List of next nodes to create the verticality of the SkipList
        private ArrayList<Node> previousNodes;      // List of previous nodes to create the verticality of the SkipList

        /**
         * Constructs a new Node object to be stored in the SkipList.
         * @param element - element to be stored in the node
         */
        public Node(T element) {
            this.element = element;
            nextNodes = new ArrayList<>(absoluteMaxLevel);
            previousNodes = new ArrayList<>(absoluteMaxLevel);
            level = computeLevel();
        }

        /**
         * Checks if a Node is the Head of the SkipList.
         * @return True if Node is Head, false otherwise
         */
        public boolean isHead() {
            return (this.element == null && this.previousNodes.get(0) == null) ? true : false;
        }

        /**
         * Checks if a Node is the Tail of the SkipList.
         * @return True if Node is Tail, false otherwise
         */
        public boolean isTail() {
            return (this.element == null && this.nextNodes.get(0) == null) ? true : false;
        }

        /**
         * Randomly computes the level if a Node in the SkipList.
         * @return The level of the Node
         */
        public int computeLevel() {
            // Generate random number and increment level until 0
            int level = 1;
            for(int i = 0; i < currLevel - 1; i++) {
                int val = levelRandomizer.nextInt(2);
                if(val == 1) level++;
                else if(val == 0) break;
            }
        
            // Return the computed level
            return level;
        }
        
        /**
         * Links a Node to two other Nodes.
         * @param precedingNodes - List of all Nodes previous the point at which the current Node is to be inserted
         * @param reBalancing - {@code true} if method is called during SkipList reBalancing
         * @return If {@code reBalancing == true}, returns the updated ArrayList of Preceding Nodes based on the changes to the list from the insertion of the new Node 
         */
        public ArrayList<Node> linkNode(ArrayList<Node> precedingNodes, boolean reBalancing) {
            for(int i = 0; i < this.level; i++) {
                this.nextNodes.add(i, precedingNodes.get(i).nextNodes.get(i));
                this.previousNodes.add(i, precedingNodes.get(i));
                precedingNodes.get(i).nextNodes.get(i).previousNodes.set(i, this);
                precedingNodes.get(i).nextNodes.set(i, this);
                if(reBalancing) precedingNodes.set(i, this);
            }
            return precedingNodes;
        }

        /**
         * Removes a node from between two other nodes.
         */
        public void unLinkNode() {
            // Update this Nodes NextNodes and PreviousNodes
            for(int i = 0; i < this.nextNodes.size(); i++) {
                this.nextNodes.get(i).previousNodes.set(i,this.previousNodes.get(i));
                this.previousNodes.get(i).nextNodes.set(i,this.nextNodes.get(i));
            }
        }
    }

    // Iterator Class for the SkipList
    private class SkipListSetIterator implements Iterator<T> {

        // Attributes
        private Node currNode;       // Current Node being considered by the iterator 
        private Node nextNode;       // Next Node to be considered by the iterator
        private boolean called;      // Monitors if 'next' has been called prior to remove being called

        /**
         * Constructs an Iterator over the elements of this SkipListSet
         */
        public SkipListSetIterator() {
            nextNode = currNode = null;
            called = false;
            if(!isEmpty()) nextNode = head.nextNodes.get(0);
        }
        
        /**
         * @return {@code true} if the iteration has more elements.
         */
        @Override
        public boolean hasNext() {
            return (!nextNode.isTail());
        }

        /**
         * @return the next element in the iteration
         * @throws NoSuchElementException if the iteration has no more elements
         */
        @Override
        public T next() {
            currNode = nextNode;
            nextNode = currNode.nextNodes.get(0);
            if(!currNode.isTail()) {
                called = true;
                return currNode.element;
            }
            else throw new NoSuchElementException();
        }

        /**
         * Removes from the SkipList the last element returned by this iterator.
         * @throws IllegalStateException if the {@code next} method has not
         *         yet been called, or the {@code remove} method has already
         *         been called after the last call to the {@code next}
         *         method
         */
        @Override
        public void remove() {
            if(currNode == null || currNode.isTail() || currNode.isHead()) return;
            if(!called) throw new IllegalStateException();
            called = false;
            currNode.unLinkNode();
            size--;
            reSize(false);
        }
    }

    /**
     * Constructs a new SkipListSet 
     */
    public SkipListSet() {

        // Initialize the basic attributes
        absoluteMinLevel = currLevel = 8;
        absoluteMaxLevel = 24;
        size = 0;

        // Initialize Node Level Randomizer
        levelRandomizer = new SplittableRandom();
	    
        // Initialize and differntiate the Head and Tail 
        head = new Node(null);
        tail = new Node(null) ;
        head.level = tail.level = currLevel;
        for(int i = 0; i < absoluteMaxLevel; i++) {
            head.previousNodes.add(i, null);    // Head has no previous Nodes
            head.nextNodes.add(i, tail);                // Set Head next Nodes to Tail
            tail.previousNodes.add(i, head);            // Set Tail previous Nodes Head
            tail.nextNodes.add(i, null);        // Tail has no next Nodes
        }
    }

    /**
     * Search the Skip List for the indicated element
     * @param e - Element to be found in the Skip List
     * @return The list of nodes preceding the target elements location in the list or, if the target is present, returns 
     *         a list whose sole element is the node that holds said target
     */
    private ArrayList<Node> search(T e) {
        
        // Start search at the head 
        int listLevel = head.level;
        Node currNode = head;

        // Stack of pointers to relevant preivous nodes (added as)
        ArrayList<Node> location = new ArrayList<>(absoluteMaxLevel);
        for(int i = 0; i < listLevel; i++) location.add(null);

        // Check and account for first layers with only head and tail connections 
        while(listLevel > 0 && currNode.nextNodes.get(listLevel - 1).isTail()) location.set(--listLevel,currNode);  

        // Search through every level of the Skip List if there are any present
        if(listLevel > 0) currNode = head.nextNodes.get(listLevel - 1); 
        while(listLevel > 0 && !isEmpty()) {
            // Compare the target element with the current nodes element
            int comparison = currNode.element.compareTo(e);

            // Current element < target element, move right
            if(comparison < 0) {
                if(currNode.nextNodes.get(listLevel - 1).isTail()) location.set(--listLevel, currNode); // Layer Node Boundary found, move down, then right
                else currNode = currNode.nextNodes.get(listLevel - 1);  // Simply move right
            }

            // Current element > target element, move left and then down
            else if(comparison > 0) {
                // Node boundary for layer found: add node to list and decrement layer + currNode
                location.set(--listLevel, currNode.previousNodes.get(listLevel));   // Layer Node Boundary Found, move down
                if(currNode.previousNodes.get(listLevel).isHead() && listLevel > 0) currNode = head.nextNodes.get(listLevel - 1);
                else currNode = currNode.previousNodes.get(listLevel);  // Move left to the previous node
            }

            // Current element = target element
            else if(comparison == 0) {
                location = new ArrayList<>(1);
                location.add(currNode);
                break;
            }
        }

        // Return stack of relevant previous pointers
        return location;
    }

    /**
     * Adds the indicated element to this SkipListSet if it is not already present.
     * @param e - element to be added to the SkipListSet
     * @return {@code true} if the element was successfully added to the SkipListSet and {@code false} otherwise
     */
    @Override
    public boolean add(T e) {

        // Create Node to add and retrieve insertion location
        Node newNode = new Node(e);
        ArrayList<Node> insertionLocation = search(e);

        // Add to Skip List if target wasn't found in search
        if(insertionLocation.size() > 1) {
            newNode.linkNode(insertionLocation, false);
            size++;
            reSize(true);
            return true;
        }  

        // Return false if element was already present in Skip List
        return false;
    }

    /**
     * Removes the indicated element to this SkipListSet if it is present.
     * @param o - object to be removed to the SkipListSet
     * @return {@code true} if the element was successfully removed to the SkipListSet and {@code false} otherwise
     */
    @Override
    @SuppressWarnings("unchecked")
    public boolean remove(Object o) {

        // Find the element to remove
        ArrayList<Node> target = search((T) o);

        // Remove from Skip List
        if(target.size() == 1 && !isEmpty()) {
            target.get(0).unLinkNode();
            size--;
            reSize(false);
            return true;
        }

        //  Return true if element was not present in list
        return false;
    }

    /**
     * Resize the Skip List each time a running size boundary has been passed.
     * @param increment - {@code true} if this is called while adding to the Skip List, {@code false} if called while removing
     */
    private void reSize(boolean increment) {
        // Check if the current size is a power of 2 and if the current level is within accepted bounds
        int sizeBound = (int) Math.pow(2,absoluteMinLevel) - 1;
        boolean powerOf2 = (size & size-1) == 0; 
        boolean acceptableLevel = (currLevel < absoluteMaxLevel) && (size >= sizeBound);
        
        // Increase list size
        if(powerOf2 && acceptableLevel && increment) head.level = tail.level = ++currLevel;

        // Decrease list size
        else if(((powerOf2 && acceptableLevel) || (size == sizeBound && currLevel == currLevel + 1)) && !increment) {
            // Set the levels of the head, tail, and list
            head.level = tail.level = --currLevel;
            head.nextNodes.set(currLevel, tail);
            tail.previousNodes.set(currLevel, head);

            // Truncate Nodes that are now too tall
            for(Node node = head.nextNodes.get(0); !node.isTail(); node = node.nextNodes.get(0)) {
                if(node.level > currLevel) {
                    node.level = currLevel;
                    node.previousNodes.remove(currLevel);
                    node.nextNodes.remove(currLevel);
                }
            }
        }
    }

    /**
     * Rebalances the Skip List in the event that many deletions have degenerated the randomized distribution of the Nodes to. More 
     * Specifically, when too many "high level" Nodes have been removed from the List.
     */
    public void reBalance() {
        // ArrayList to store Nodes that precede the current Node at level of the list
        ArrayList<Node> wall = new ArrayList<>(currLevel);
        for(int i = 0 ; i < currLevel; i++) wall.add(head);

        // Loop through each Node in the SkipList and rebalance them
        for(Node currNode = head.nextNodes.get(0); !currNode.isTail(); currNode = currNode.nextNodes.get(0)) {
            // Remove and Reset the Node
            currNode.unLinkNode();
            currNode.level = currNode.computeLevel(); 
            currNode.previousNodes.clear();
            currNode.nextNodes.clear();
            
            // Reinsert Node with new Level and update preceding Nodes
            wall = currNode.linkNode(wall, true);
        } 
    }

    /**
     * Returns the number of elements stored within this SkipListSet
     * @return the number of elements stored within this SkipListSet. If 
     * this SkipListSet has more thant {@code Integer.MAX_VALUE}, returns
     * {@code Integer.MAX_VALUE}.
     */
    @Override
    public int size() {
        return (size < Integer.MAX_VALUE) ? size : Integer.MAX_VALUE;
    }

    /**
     * Returns {@code true} if this SkipListSet contains no elements.
     * @return {@code true} if this SkipListSet contains no elements.
     */
    @Override
    public boolean isEmpty() {
        return (size() == 0);
    }

    /**
     * Checks if the indicated object is present in the Skip List.
     * @param o - object to search for in this SkipListSet
     * @return {@code true} if the indicated object is present in the List.
     */
    @Override
    @SuppressWarnings("unchecked")
    public boolean contains(Object o) {
        ArrayList<Node> n = search((T) o);
        return (n.size() == 1 && n.get(0).element.equals((T) o)) ? true : false;
    }

    /**
     * Returns an iterator over the elements in this set that follows the ordering of the indicated SkipListSet type.
     * @return an iterator over the elements in this set that follows the ordering of the indicated SkipListSet type.
     */
    @Override
    public Iterator<T> iterator() {
        return new SkipListSetIterator();
    }

    /**
     * Returns an array containing all the objects in this SkipListSet.
     * @return an array containing all the objects in this SkipListSet.
     */
    @Override
    public Object[] toArray() {
        int i = 0;
        Object[] res = new Object[size];
        for(Node node = head.nextNodes.get(0); !node.isTail(); node = node.nextNodes.get(0)) {
            res[i++] = node.element;
        }
        return res;
    }

    /**
     * Returns an array of the indicated SkipListSet type containing all the objects in this SkipListSet.
     * @param a - array of the indicated SkipListSet type to add the SkipList elements to.
     * @throws ArrayStoreException if the runtime type of the specified array
     *         is not a supertype of the runtime type of every element in this
     *         set
     * @throws NullPointerException if the specified array is null
     * @return an array of the indicated SkipListSet type containing all the objects in this SkipListSet.
     */
    @Override
    @SuppressWarnings({"unchecked", "hiding"})
    public <T> T[] toArray(T[] a) {
        
        if(a == null) throw new NullPointerException();
        if(!(a instanceof T[])) throw new ArrayStoreException();
        if (a.length < size) a = (T[]) java.lang.reflect.Array.newInstance(a.getClass().getComponentType(), size);

        int i = 0;
        Object[] res = a;
        for(Node node = head.nextNodes.get(0); !node.isTail(); node = node.nextNodes.get(0)) {
            res[i++] = node.element;
        }
        if (a.length > size) a[size] = null;
        return a;
    }
    
    /**
     * Compares the indicated object with this SkipListSet for equality.
     * @param o - object to be compared for equality. Should be a set.
     * @return {@code true} if the indicated object is a set that holds the same elements as 
     *         this SkipListSet
     */
    @Override 
    public boolean equals(Object o) {
        if(o == this) return true;
        if(!(o instanceof Set)) return false;
        Set<?> c = (Set<?>) o;
        try {
            return (size == c.size() && this.containsAll(c));
        } catch (ClassCastException | NullPointerException e) {
            return false;
        }
    }

    /**
     * Returns {@code true} if this SkipListSet contains all of the elements within the indicated collection.
     * @param c - collection to be checked for containment within this SkipListSet
     * @return {@code true} if this SkipListSet contains all of the elements within the indicated collection and {@code false} otherwise.
     */
    @Override
    public boolean containsAll(Collection<?> c) {
        for (Object e : c) if (!contains(e)) return false;
        return true;
    }

    /**
     * Adds all of the elements within the indicated collection to this SkipListSet.
     * @param c - collection of elements to be added to this SkipListSet
     * @return {@code true} if this set changed as a result of the call and {@code false} otherwise.
     */
    @Override
    public boolean addAll(Collection<? extends T> c) {
        int s = size;
        for(T e : c) add(e);
        return (s != size) ? true : false;
    }

    /**
     * Removes all of the elements in this SkipListSet except those within the indicated collection.
     * @param c - collection of elements to be retained in this SkipListSet
     * @return {@code true} if this set changed as a result of the call and {@code false} otherwise.
     */
    @Override
    public boolean retainAll(Collection<?> c) {
        int s = size;
        for(Node currNode = head.nextNodes.get(0); !currNode.isTail(); currNode = currNode.nextNodes.get(0)) {
            if(!c.contains(currNode.element)) remove(currNode.element);
        }
        return (s != size) ? true : false;
    }
    
    /**
     * Removes all of the elements from this SkipListSet that are also present in the indicated collection.
     * @param c - collection of elements to be removed from this SkipListSet
     * @return {@code true} if this set changed as a result of the call and {@code false} otherwise.
     */
    @Override
    public boolean removeAll(Collection<?> c) {
        int s = size;
        for(Object e : c) remove(e);
        return (s != size) ? true : false;
    }

    /**
     * Empties the SkipListSet
     */
    @Override
    public void clear() {
        // Reset SkipListSet Attributes
        size = 0;
        head.level = tail.level = currLevel = absoluteMinLevel; 
        head = new Node(null); 
        tail = new Node(null);
        for(int i = 0; i < absoluteMaxLevel; i++) {
            head.previousNodes.add(i, null);    // Head has no previous Nodes
            head.nextNodes.add(i, tail);                // Set head next Nodes to corresponding tails
            tail.previousNodes.add(i, head);            // Set tail previous Nodes to corresponding heads
            tail.nextNodes.add(i, null);        // Tail has no next Nodes
        }
    }

    /**
     * Returns the first element of this SkipListSet (based on the ordering of the indicated SkipListSet type).
     * @throws NoSuchElementException if this SkipListSet is empty.
     * @return the first element of this SkipListSet (based on the ordering of the indicated SkipListSet type).
     */
    @Override
    public T first() {
        if(isEmpty()) throw new NoSuchElementException();
        return head.nextNodes.get(0).element;
    }

    /**
     * Returns the last element of this SkipListSet (based on the ordering of the indicated SkipListSet type).
     * @throws NoSuchElementException if this SkipListSet is empty.
     * @return the last element of this SkipListSet (based on the ordering of the indicated SkipListSet type).
     */
    @Override
    public T last() {
        if(isEmpty()) throw new NoSuchElementException();
        return tail.previousNodes.get(0).element;
    }
    
    /**
     * Does nothing and returns null as directed by project rules.
     */
    @Override
    public Comparator<? super T> comparator() {
        return null; 
    }

    /**
     * Unsupported as directed by project rules.
     * @throws UnsupportedOperationException
     */
    @Override
    public SortedSet<T> subSet(T fromElement, T toElement) {
        throw new UnsupportedOperationException("Unimplemented method 'subSet'");
    }

    /**
     * Unsupported as directed by project rules.
     * @throws UnsupportedOperationException
     */
    @Override
    public SortedSet<T> headSet(T toElement) {
        throw new UnsupportedOperationException("Unimplemented method 'headSet'");
    }

    /**
     * Unsupported as directed by project rules.
     * @throws UnsupportedOperationException
     */
    @Override
    public SortedSet<T> tailSet(T fromElement) {
        throw new UnsupportedOperationException("Unimplemented method 'tailSet'");
    }

    /**
     * Returns the hashcode value for this SkipListSet by taking the sum of the hashcodes of each element within.
     * @return the hashcode value for this SkipListSet by taking the sum of the hashcodes of each element within.
     */
    @Override 
    public int hashCode() {
        int hashCode = 0;
        for(Node currNode = head.nextNodes.get(0); !currNode.isTail(); currNode = currNode.nextNodes.get(0)) {
            if(currNode.element != null) hashCode += currNode.element.hashCode();
        }
        return hashCode;
    } 
}


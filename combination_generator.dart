// This code is hosted on my github: https://github.com/dmvvilela
// The idea started here: https://compprog.wordpress.com/2007/10/17/generating-_combinations-1/
// I have translated this C program into Dart, corrected a mistake on it and added some new features.
//
// What this file actually do:
// Given a set of numbers {1, 2, 3, ..., n}, return all the combinations without repetition of this set.
//
// So, what are the ways of choosing 2 elements from a set of 4, {1, 2, 3, 4}?
// {1, 2}
// {1, 3}
// {1, 4}
// {2, 3}
// {2, 4}
// {3, 4}
// Repeat this for other subsets sizes (1, 3, 4).

class CombinationGenerator {
  List<int> _combinations = List<int>();

  void _initializeCombinations(subsetSize) {
    _combinations.clear();

    for (int i = 0; i < subsetSize; i++) {
      _combinations.add(i);
    }
  }

  /*
   *  _nextCombination(int subsetSize, int setSize)
   *      Generates the next combination of n elements as k after _combinations
   *
   *  _combinations => the previous combination ( use (0, 1, 2, ..., k) for first)
   *  subsetSize (k) => the size of the subsets to generate
   *  setSize (n)    => the size of the original set
   *
   *  Returns: 1 if a valid combination was found 0, otherwise.
  */
  int _nextCombination(subsetSize, setSize) {
    int i = subsetSize - 1;
    _combinations[i]++;

    while ((i > 0) && (_combinations[i] >= setSize - subsetSize + 1 + i)) {
      i--;
      _combinations[i]++;
    }

    /* Combination (n-k, n-k+1, ..., n) reached */
    if (_combinations[0] > setSize - subsetSize) {
      /* No more _combinations can be generated */
      return 0;
    }

    /* _combinations now looks like (..., x, n, n, n, ..., n).
    Turn it into (..., x, x + 1, x + 2, ...) */
    for (i = i + 1; i < subsetSize; ++i) {
      _combinations[i] = _combinations[i - 1] + 1;
    }

    return 1;
  }

  List<int> _indexer(subsetSize) {
    List<int> indexes = new List<int>();

    for (int i = 0; i < subsetSize; i++) {
      indexes.add(_combinations[i]);
    }

    return indexes;
  }

  List<List<int>> getSubsetCombinations(subsetSize, setSize) {
    List<List<int>> sublist = new List<List<int>>();

    if (subsetSize > setSize) return null;

    /* If it was used before, it has to be reinitialized. */
    _initializeCombinations(subsetSize);

    /* Return the first combination */
    sublist.add(_indexer(subsetSize));

    /* Generate and return all the other _combinations */
    while (_nextCombination(subsetSize, setSize) > 0) {
      sublist.add(_indexer(subsetSize));
    }

    return sublist;
  }

  List<List<int>> getAllSetCombinations(setSize) {
    List<List<int>> list = new List<List<int>>();

    for (int i = setSize; i > 0; i--) {
      list.addAll(getSubsetCombinations(i, setSize));
    }

    return list;
  }
}

void main() {
  var cg = new CombinationGenerator();

  print(cg.getSubsetCombinations(3, 4));

  print(""); // new line to see results better

  print(cg.getAllSetCombinations(4));
}

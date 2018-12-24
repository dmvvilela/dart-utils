// The idea started here: https://compprog.wordpress.com/2007/10/17/generating-combinations-1/
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
  /* The size of the set; for {1, 2, 3, 4} it's 4 */
  final int setSize;
  /* The size of the subsets; for {1, 2}, {1, 3}, ... it's 2 */
  final int subsetSize;
  /* combinations[i] is the index of the i-th element in the combination */
  List<int> combinations = List<int>();

  CombinationGenerator(this.setSize, this.subsetSize) {
    /* Setup combinations for the initial combination */
    for (int i = 0; i < setSize; i++) {
      combinations.add(i);
    }
  }

  /*
      _nextCombination(List<int> combinations, int subsetSize, int setSize)
          Generates the next combination of n elements as k after combinations

      comb => the previous combination ( use (0, 1, 2, ..., k) for first)
      subsetSize (k) => the size of the subsets to generate
      setSize (n)    => the size of the original set

      Returns: 1 if a valid combination was found 0, otherwise.
  */
  int _nextCombination(combinations, subsetSize, setSize) {
    int i = subsetSize - 1;
    combinations[i]++;
    while ((i > 0) && (combinations[i] >= setSize - subsetSize + 1 + i)) {
      i--;
      combinations[i]++;
    }

    /* Combination (n-k, n-k+1, ..., n) reached */
    if (combinations[0] > setSize - subsetSize) {
      /* No more combinations can be generated */
      return 0;
    }

    /* comb now looks like (..., x, n, n, n, ..., n).
    Turn it into (..., x, x + 1, x + 2, ...) */
    for (i = i + 1; i < subsetSize; ++i) {
      combinations[i] = combinations[i - 1] + 1;
    }

    return 1;
  }

  void _printer(combinations, subsetSize) {
    var string = StringBuffer('{');

    for (int i = 0; i < subsetSize; i++) {
      string.write(combinations[i] + 1);
    }

    string.write("\b\b}\n");

    print(string);
  }

  void printCombinations() {
    /* Print the first combination */
    _printer(combinations, subsetSize);

    /* Generate and print all the other combinations */
    while (_nextCombination(combinations, subsetSize, setSize) > 0) {
      _printer(combinations, subsetSize);
    }
  }
}


void main() {
  var cg = new CombinationGenerator(4, 3);

  cg.printCombinations();
}

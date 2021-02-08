require 'set'

Match = Struct.new(:a, :b, :size)

class Matcher

  def calculate_ratio(matches, length)
    if length
      2.0 * matches / length
    else
      1.0
    end
  end

  private :calculate_ratio

  def initialize(a = '', b = '', autojunk = true)
    @first = @second = nil
    @autojunk = autojunk
    set_seqs(a, b)
  end

  def set_seqs(first, second)
    set_seq1(first)
    set_seq2(second)
  end

  def set_seq1(first)
    nil if first.eql?(@first)
    @first = first
    @matching_blocks = nil
  end

  def set_seq2(second)
    nil if second.eql?(@second)
    @second = second
    @matching_blocks = nil
    @fullbcount = nil
    chain_b
  end

  def chain_b
    @b2j = Hash.new(0)
    @second.each_char.with_index do |i, el|
      indices = @b2j.fetch(el, [])
      indices.append(i)
    end

    # Purge popular elements for b that are not junk
    @bpopular = Set[]
    n = @second.length
    return unless @autojunk && (n >= 200)

    ntest = n.div(100) + 1
    @b2j.each_pair do |el, ind|
      @bpopular.add(el) if ind.length > ntest
    end
    @bpopular.each do |el|
      @b2j.delete(el)
    end
  end

  private :chain_b

  def find_longest_match(alow = 0, ahigh = nil, blow = 0, bhigh = nil)
    a = @first
    b = @second
    ahigh = a.length if ahigh.eql?(nil)
    bhigh = b.length if bhigh.eql?(nil)
    besti = alow
    bestj = blow
    bestsize = 0
    j2len = {}
    nothing = []

    (alow..ahigh).each do |i|
      newj2len = {}
      @b2j.fetch(a[i], nothing).each do |j|
        # a[i] matches b[j]
        next if j < blow
        break if j >= bhigh

        k = newj2len[j] = j2len.get(j - 1, 0) + 1
        next unless k > bestsize

        besti = i - k + 1
        bestj = j - k + 1
        bestsize = k
      end
      j2len = newj2len
    end
    while besti > alow && bestj > blow && a[besti - 1] == b[bestj - 1]
      besti -= 1
      bestj -= 1
      bestsize += 1
    end
    while besti + bestsize < ahigh && bestj + bestsize < bhigh && a[besti + bestsize] == b[bestj + bestsize]
      bestsize += 1
    end
    Match.new(besti, bestj, bestsize)
  end

  def get_matching_blocks
    @matching_blocks unless @matching_blocks.nil?
    asize = @first.length
    bsize = @second.length

    queue = [[0, asize, 0, bsize]]
    matching_blocks = []
    until queue.empty?
      alow, ahigh, blow, bhigh = queue.pop
      i, j, k = x = find_longest_match(alow, ahigh, blow, bhigh)
      next unless k

      matching_blocks.append(x)
      queue.append([alow, i, blow, j]) if alow < i && blow < j
      queue.append([i + k, ahigh, j + k, bhigh]) if i + k < ahigh && j + k < bhigh
    end
    matching_blocks.sort

    i1 = j1 = k1 = 0
    non_adjacent = []
    matching_blocks.each do |i2, j2, k2|
      # Is this block adjacent to i1, j1, k1?
      if i1 + k1 == i2 and j1 + k1 == j2
        # Yes, so collapse them -- this just increases the length of
        # the first block by the length of the second, and the first
        # block so lengthened remains the block to compare against.
        k1 += k2
      else
        # Not adjacent.  Remember the first block (k1==0 means it's
        # the dummy we started with), and make the second block the
        # new block to compare against.

        non_adjacent.append([i1, j1, k1]) if k1
        i1 = i2
        j1 = j2
        k1 = k2
      end
    end
    non_adjacent.append([i1, j1, k1]) if k1
    non_adjacent.append([asize, bsize, 0])
    @matching_blocks = [non_adjacent.each.map { |el1, el2, el3| Match.new(el1, el2, el3) }]
    @matching_blocks
  end

  def ratio
    matches = 0
    get_matching_blocks.each { |triple| matches += triple.size }
    calculate_ratio(matches, @first.length + @second.length)
  end
end

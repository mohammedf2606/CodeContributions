require_relative 'matcher'

class Contribution
  def initialize(rev, user)
    init_variables(rev.to_s, user)
    init_commits(0, rev.length, @new_commit_no)
    move_to_current
  end

  def update(rev, user)
    @new_code_text = rev.to_s
    @new_commit_no = @commit_no + 1
    @user_index[@new_commit_no] = user
    matches = calc_line_change(rev.to_s)

    pointer = 0
    sort_lambda = ->(l) { l[1] }
    matches.sort_by(&sort_lambda)
    matches.each do |code_block_match|
      if code_block_match[1] != pointer && code_block_match[1] < @new_code_text.length
        init_commits(0, code_block_match[1] - pointer, @new_commit_no)
        pointer += code_block_match[1] - pointer
      end
      add_matching_blocks(code_block_match[0], code_block_match[2])
      pointer += code_block_match[2]
    end
    if @new_code_text.length > @new_code.length
      init_commits(0, @new_code_text.length - @new_code.length, @new_commit_no)
    end
    move_to_current
  end

  def calculate_ownership(log_base = 10)
    aggregate = Hash.new(0)
    counts = Hash.new(0)
    sums_persistence = Hash.new(0)
    avg_persistence = Hash.new(0)
    # auxiliary counter
    i = 0

    # inverting scores to get persistence
    persistence = @code.map do |x|
      @commit_no + 1 - x
    end
    # self.code and persistence are exactly the same length
    @code.each do |x|
      if counts.fetch(x, 0).zero?
        counts[x] = 1
      else
        counts[x] += 1
      end
      if aggregate.fetch(x, 0).zero?
        aggregate[x] = persistence[i]
      else
        aggregate[x] += persistence[i]
      end
      i += 1
    end
    counts.each do |x|
      if sums_persistence.fetch(@user_index[x], 0).zero?
        sums_persistence[@user_index[x[0]]] = counts[x[0]]
        avg_persistence[@user_index[x[0]]] = aggregate[x[0]]
      else
        sums_persistence[@user_index[x[0]]] += counts[x]
        avg_persistence[@user_index[x[0]]] += aggregate[x]
      end
    end
    avg_persistence.each_key do |x|
      avg_persistence[x] = Math.log(avg_persistence[x] + 1, log_base).round(2)
    end
    [sums_persistence, avg_persistence]
  end

  private

  def init_variables(rev, user)
    @new_code_text = rev
    @new_code = []
    @user_index = Hash.new(0)
    @commit_no = 0
    @new_commit_no = @commit_no + 1
    @user_index[@new_commit_no] = user
  end

  def init_commits(start, stop, number)
    (start..stop).each do
      @new_code.append(number)
    end
  end

  def move_to_current
    @code = @new_code
    @code_text = @new_code_text
    @commit_no = @new_commit_no
  end

  def add_matching_blocks(old_pos, length)
    (0..length).each do |x|
      @new_code.append(@code[x + old_pos])
    end
  end

  def calc_line_change(revision, threshold = 0.3)
    matches = []
    original = @code_text.lines.map(&:chomp)
    new = revision.lines.map(&:chomp)
    found = TRUE

    line_char_original = []
    line_char_new = []
    line_count = 0

    (0..original.length - 1).each do |x|
      line_char_original.append(line_count)
      line_count += original[x].length
    end
    line_count = 0
    (0..new.length - 1).each do |y|
      line_char_new.append(line_count)
      line_count += new[y].length
    end

    count = Hash.new(0)
    new.each do |word|
      count[word] += 1
    end

    diffs = []
    tmp_new = new # Create temporary list for reference
    y_list = (0..new.length - 1).to_a # Temporary list used for dynamic recursion
    counter = 0

    (0..original.length - 1).each do |x|
      diffs.append([])
      if (count[original[x]]).positive?
        y = y_list.index(tmp_new.index(original[x]))
        diffs[x].append([x, y_list[y], 1.0,
                         [Match.new(0, 0, original[x].length),
                          Match.new(original[x].length, original[x].length, 0)]])
        y_list.delete(y_list[y])
        tmp_new[tmp_new.index(original[x])] = 0
        count[original[x]] -= 1
      else
        (0..y_list.length - 1).each do |z|
          counter += 1
          line_diff_result = Matcher.new(original[x], new[y_list[z]], false)
          if line_diff_result.ratio == 1
            diffs[x].append([x, y_list[z], line_diff_result.ratio,
                             line_diff_result.get_matching_blocks])
            y_list.delete(y_list[z])
            break
          else
            diffs[x].append([x, y_list[z], line_diff_result.ratio,
                             line_diff_result.get_matching_blocks])
          end
        end
      end
    end

    to_delete = -9999
    while found.eql?(true)
      found = false
      max_match = [0, 0, 0, 0]
      (0..diffs.length - 1).each do |x|
        (0..diffs[x].length - 1).each do |y|
          if diffs[x][y][1] == to_delete
            diffs[x][y] = [0, 0, 0, 0]
          elsif diffs[x][y][2] > threshold && max_match[2] < diffs[x][y][2]
            max_match = [diffs[x][y][0], diffs[x][y][1], diffs[x][y][2], diffs[x][y][3], x]
          end
        end
      end
      next unless max_match[2] != 0

      found = true
      max_match[3].each do |m|
        next unless m[2] != 0 && m.is_a?(Match)

        matches.append([line_char_original[max_match[0]] + m[0],
                        line_char_new[max_match[1]] + m[1],
                        m[2]])
      end
      diffs.delete(diffs[max_match[4]])
      to_delete = max_match[1]
    end
    matches
  end
end

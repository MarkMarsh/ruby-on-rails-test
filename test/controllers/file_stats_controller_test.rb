require 'test_helper'

class FileStatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @file_stat = file_stats(:one)
  end

  test "should get index" do
    get file_stats_url
    assert_response :success
  end

  test "should get new" do
    get new_file_stat_url
    assert_response :success
  end

  test "should create file_stat" do
    assert_difference('FileStat.count') do
      post file_stats_url, params: { file_stat: { filename: @file_stat.filename, least_status: @file_stat.least_status, most_status: @file_stat.most_status, palindrome_status: @file_stat.palindrome_status, username: @file_stat.username } }
    end

    assert_redirected_to file_stat_url(FileStat.last)
  end

  test "should show file_stat" do
    get file_stat_url(@file_stat)
    assert_response :success
  end

  test "should get edit" do
    get edit_file_stat_url(@file_stat)
    assert_response :success
  end

  test "should update file_stat" do
    patch file_stat_url(@file_stat), params: { file_stat: { filename: @file_stat.filename, least_status: @file_stat.least_status, most_status: @file_stat.most_status, palindrome_status: @file_stat.palindrome_status, username: @file_stat.username } }
    assert_redirected_to file_stat_url(@file_stat)
  end

  test "should destroy file_stat" do
    assert_difference('FileStat.count', -1) do
      delete file_stat_url(@file_stat)
    end

    assert_redirected_to file_stats_url
  end
end

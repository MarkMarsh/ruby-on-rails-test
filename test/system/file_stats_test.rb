require "application_system_test_case"

class FileStatsTest < ApplicationSystemTestCase
  setup do
    @file_stat = file_stats(:one)
  end

  test "visiting the index" do
    visit file_stats_url
    assert_selector "h1", text: "File Stats"
  end

  test "creating a File stat" do
    visit file_stats_url
    click_on "New File Stat"

    fill_in "Filename", with: @file_stat.filename
    check "Least status" if @file_stat.least_status
    check "Most status" if @file_stat.most_status
    check "Palindrome status" if @file_stat.palindrome_status
    fill_in "Username", with: @file_stat.username
    click_on "Create File stat"

    assert_text "File stat was successfully created"
    click_on "Back"
  end

  test "updating a File stat" do
    visit file_stats_url
    click_on "Edit", match: :first

    fill_in "Filename", with: @file_stat.filename
    check "Least status" if @file_stat.least_status
    check "Most status" if @file_stat.most_status
    check "Palindrome status" if @file_stat.palindrome_status
    fill_in "Username", with: @file_stat.username
    click_on "Update File stat"

    assert_text "File stat was successfully updated"
    click_on "Back"
  end

  test "destroying a File stat" do
    visit file_stats_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "File stat was successfully destroyed"
  end
end

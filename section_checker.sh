#!/bin/bash

# color mode: three: console/html/none
COLOR_MODE=${COLOR_MODE:-"console"}
SC_MSG_WIDTH=${SC_MSG_WIDTH:-`tput cols`}
SC_SECTION_CH=${SC_SECTION_CH:-+}
SC_SUB_CHECK_CH=${SC_SUB_CHECK_CH:--}

if test "$COLOR_MODE" = "console" ; then
  sc_succ_color="tput setaf 2"
  sc_fail_color="tput setaf 1"
  sc_clear_color="tput sgr0"
elif test "$Color_mode" = "html" ; then
  sc_succ_color="printf %s <font color='green' >"
  sc_fail_color="printf %s <font color='red' >"
  sc_clear_color="printf %s </font>"
else
  sc_succ_color=
  sc_fail_color=
  sc_lear_color=
fi

section_title="None"
section_result="failed"
section_total=1
section_global_fail_result=0
section_global_success_result=0
section_sub=0
section_prefix=""
section_sub_prefix=""
section_titles=("None")
section_check_msg_length=$(( ($SC_MSG_WIDTH - 30)/2))


sc_line() {
	var=$1
	if test "$(( $var <= 0 ))" = "1" ; then
		echo ""
		return
	fi
	ch="%.s${2:-'-'}"
	var=`seq 1 $var`
	printf "${ch}" $var
}

sc_line_mid() {
  line=$1
  msg=$2
  printf "%s%s%s" "${line:0:$(( (${#line} - ${#msg})/2 ))}" "${msg}" "${line:$(( (${#line} + ${#msg})/2))}"
}

section_begin_ending_msg=`sc_line $(( $SC_MSG_WIDTH - 10 )) ' '``sc_line 10 "$SC_SECTION_CH"`
section_end_ending_msg=`sc_line $(( $SC_MSG_WIDTH - 10 )) ' '`
section_end_ending_msg_2=`sc_line 10 '-'`

SC_CHECK_MATH() {
  a=$1
  op=$2
  b=$3
  msg=$4
  color=""
  show_msg=""
  if test "$(( $a $op $b ))" = "0" ; then
    color="$sc_fail_color"
    section_result="failed"
    section_total=0
    section_global_fail_result=$(( $section_global_fail_result + 1 ))
    show_msg="$a $op $b"
  else
    color="$sc_succ_color"
    section_result="success"
    section_global_success_result=$(( $section_global_success_result + 1 ))
    l_sec_msg_len=$(( ${section_check_msg_length} - (11 + ${#msg})/2))
    if test "$(( $l_sec_msg_len < 1 ))" = "1" ; then
      l_sec_msg_len=1
    fi
    show_msg="${a:0:$l_sec_msg_len} $op ${b:0:${l_sec_msg_len}}"
  fi
  if test "$msg" != "" ; then
    t_msg="${section_sub_prefix} checking $msg : $show_msg   "
    printf "%s%s" "$t_msg" "${section_end_ending_msg:$(( ${#t_msg}+${#section_result}))}" 
    $color
    printf "%s" "$section_result"
    if test "$color" != "" ; then  
      $sc_clear_color
    fi
    printf "\n"
  fi
}

SC_CHECK_MSG() {
  a=$1
  op=$2
  b=$3
  msg=$4
  color=""
  show_msg=""
  if ! test "$a" $op "$b"; then
    color="$sc_fail_color"
    section_result="failed"
    section_total=0
    section_global_fail_result=$(( $section_global_fail_result + 1 ))
    show_msg="$a $op $b"
  else
    color="$sc_succ_color"
    section_result="success"
    section_global_success_result=$(( $section_global_success_result + 1 ))
    l_sec_msg_len=$(( ${section_check_msg_length} - (11 + ${#msg})/2))
    if test "$(( $l_sec_msg_len < 1 ))" = "1" ; then
      l_sec_msg_len=1
    fi
    show_msg="${a:0:${l_sec_msg_len}} $op ${b:0:${l_sec_msg_len}}"
  fi

  if test "$msg" != "" ; then
    t_msg="${section_sub_prefix} checking $msg : $show_msg   "
    printf "%s%s" "$t_msg" "${section_end_ending_msg:$(( ${#t_msg}+${#section_result}))}"
    $color
    printf "%s" "$section_result"
    if test "$color" != "" ; then
      $sc_clear_color
    fi
    printf "\n"
  fi
}

SC_BEGIN_SECTION() {
  section_title=$1
  section_titles[$section_sub]=$section_title
  section_prefix=`sc_line $section_sub ' '`
  section_sub=$(( $section_sub + 1 ))
  section_prefix="${section_prefix}`sc_line $section_sub "$SC_SECTION_CH"`"
  section_sub_prefix="`sc_line ${section_sub} '  '`${SC_SUB_CHECK_CH} "
  if test "$section_title" != "" ; then
    #echo "+   Start to check ${Section}:"
    #ending_msg="                                        +++++++++++++++++++++++++++"
    msg_front="$section_prefix Start to check ${section_title}: "
    printf "%s %s\n" "$msg_front" "${section_begin_ending_msg:${#msg_front}}"
  fi
  section_total=1
}


SC_END_SECTION() {
  #empty="                                                                     "
  section_prefix="`sc_line $(( $section_sub - 1 )) ' '`-- "
  section_sub=$(( $section_sub - 1 ))
  section_title=${section_titles[$section_sub]}

  #empty="                                                            --------------     "
  #msg="--  ${Section} check result: "
  msg="${section_prefix}  ${section_title} check result: "
  result="unknown"
  color=""
  if test "$section_total" = "0" ; then
    color="$sc_fail_color"
    result="failed"
  else
    color="$sc_succ_color"
    result="success"
  fi
  #printf "%s %s " "$msg" "${section_end_ending_msg:$(( ${#msg} + ${#result} )) }" 
  #printf "%s %s " "$msg" "${section_end_ending_msg:${#msg}}" 
  printf "%s" "$msg"
  printf "%s" "${section_end_ending_msg:$(( ${#msg} + ${#result} )) }" 
  $color
  printf "%s" "$result "
  if test "$color" != "" ; then  
    $sc_clear_color
  fi
  printf "%s" "${section_end_ending_msg_2}"
  printf "\n"
  if test "$(( $section_sub < 1 ))" = "1" ; then
    printf "\n"
  fi
}

SC_PRE_HEADER() {
  sc_line $SC_MSG_WIDTH '='
  printf "\n"
  final_line="=`sc_line $(( $SC_MSG_WIDTH - 2 )) ' '`="
  echo "$final_line"
  wel_msg=$1
  sc_line_mid "$final_line" "$wel_msg"
  echo ""
  echo "$final_line"
  sc_line $SC_MSG_WIDTH '='
  echo ""
}

SC_FINAL_SUMMARY() {
  sc_line $SC_MSG_WIDTH '='
  printf "\n"
  final_line="=`sc_line $(( $SC_MSG_WIDTH - 2 )) ' '`="
  echo "$final_line"
  failed_msg="total failed: ${section_global_fail_result}"
  #printf "%s%s%s" "${final_line:0:$(( (${#final_line} - ${#failed_msg})/2 )) }" "${failed_msg}" "${final_line:$(( (${#final_line} + ${#failed_msg})/2))}"
  sc_line_mid "$final_line" "$failed_msg"
  echo ""
  success_msg="total success: ${section_global_success_result}"
  sc_line_mid "$final_line" "$success_msg"
  echo ""
  echo "$final_line"
  sc_line $SC_MSG_WIDTH '='
  echo ""
}



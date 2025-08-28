// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:launch/services/activity_service.dart';
import 'package:provider/provider.dart';
import 'package:launch/core/constant/colors.dart';
import 'package:launch/viewmodels/auth_viewmodel.dart';
import 'package:launch/viewmodels/activity_viewmodel.dart';
import 'package:launch/views/widgets/app_button.dart';
import 'package:launch/views/widgets/app_text_field.dart';
import 'package:launch/core/utils/validators.dart';
import 'package:uuid/uuid.dart';

class ActivitySelectionScreen extends StatefulWidget {
  const ActivitySelectionScreen({super.key});

  @override
  State<ActivitySelectionScreen> createState() =>
      _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  Activity? _selectedActivity;
  bool _isCreatingActivity = false;
  bool _isLoading = false;

  // 새 활동 생성 폼 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  String _selectedEmoji = '📝';

  // 이모지 목록
  final List<String> _emojis = [
    '📝',
    '📚',
    '📖',
    '💻',
    '🎨',
    '🎹',
    '🏃',
    '🏋️',
    '🧘',
    '🧠',
    '🧹',
    '🧺',
    '🍳',
    '🥗',
    '🧩',
    '🚶',
    '🚴',
    '🛌',
    '💡',
    '📈',
  ];

  @override
  void initState() {
    super.initState();

    // 선택된 활동 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityViewModel =
          Provider.of<ActivityViewModel>(context, listen: false);
      setState(() {
        _selectedActivity = activityViewModel.selectedActivity;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // 활동 선택
  void _selectActivity(Activity activity) {
    setState(() {
      _selectedActivity = activity;
    });

    // 뷰모델에 선택 활동 업데이트
    final activityViewModel =
        Provider.of<ActivityViewModel>(context, listen: false);
    activityViewModel.selectActivity(activity);
  }

  // 카운트다운 화면으로 이동
  void _navigateToCountdown() {
    if (_selectedActivity != null) {
      Navigator.of(context).pushReplacementNamed('/countdown');
    } else {
      // 선택된 활동이 없으면 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('활동을 선택해주세요.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // 새 활동 생성 폼 표시
  void _showCreateActivityForm() {
    setState(() {
      _isCreatingActivity = true;
      _nameController.clear();
      _descriptionController.clear();
      _durationController.text = '30';
      _selectedEmoji = '📝';
    });
  }

  // 새 활동 생성 폼 닫기
  void _hideCreateActivityForm() {
    setState(() {
      _isCreatingActivity = false;
    });
  }

  // 새 활동 생성
  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final activityViewModel =
          Provider.of<ActivityViewModel>(context, listen: false);

      final userId = authViewModel.user?.uid;
      if (userId == null) return;

      // 새 활동 객체 생성
      final newActivity = Activity(
        id: const Uuid().v4(),
        userId: userId,
        activityId:
            'custom_${DateTime.now().millisecondsSinceEpoch}', // 유니크한 activityId 생성
        startTime: DateTime.now(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        emoji: _selectedEmoji,
        completionCount: 0,
        createdAt: DateTime.now(),
        isCustom: true,
        durationMinutes: int.parse(_durationController.text),
        durationSeconds: 0, // 기본값 설정
        isCompleted: false, // 기본값 설정
      );

      // 활동 생성 및 선택
      final createdActivity =
          await activityViewModel.createActivity(newActivity);
      if (createdActivity != null) {
        _selectActivity(createdActivity);
        _hideCreateActivityForm();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityViewModel = Provider.of<ActivityViewModel>(context);
    final activities = activityViewModel.activities;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '활동 선택',
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.blueGrey,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isCreatingActivity
              ? _buildCreateActivityForm()
              : _buildActivitySelectionList(activities),
        ),
      ),
    );
  }

  // 활동 선택 목록 화면
  Widget _buildActivitySelectionList(List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 안내 텍스트
        Text(
          '무엇을 시작할까요?',
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          '카운트다운 후 바로 시작할 활동을 선택하세요.',
          style: TextStyle(
            fontFamily: 'jua',
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),

        // 최근 활동 라벨
        if (activities.isNotEmpty)
          const Text(
            '활동 목록',
            style: TextStyle(
              fontFamily: 'jua',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

        // 활동 목록
        Expanded(
          child: activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '등록된 활동이 없습니다.',
                        style: TextStyle(
                          fontFamily: 'jua',
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: '새 활동 추가',
                        onPressed: _showCreateActivityForm,
                        backgroundColor: AppColors.primaryColor,
                        height: 45,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: activities.length + 1, // +1 for "Add new" button
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == activities.length) {
                      // 새 활동 추가 버튼
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: GestureDetector(
                          onTap: _showCreateActivityForm,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardHighlightColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  '새 활동 추가하기',
                                  style: TextStyle(
                                    fontFamily: 'jua',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // 활동 아이템
                    final activity = activities[index];
                    final isSelected = _selectedActivity?.id == activity.id;

                    return GestureDetector(
                      onTap: () => _selectActivity(activity),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primaryColor, width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 활동 아이콘
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    // ignore: deprecated_member_use
                                    ? AppColors.primaryColor.withOpacity(0.1)
                                    : AppColors.cardHighlightColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  activity.emoji,
                                  style: const TextStyle(
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 활동 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        activity.name,
                                        style: const TextStyle(
                                          fontFamily: 'jua',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${activity.durationMinutes}분',
                                        style: TextStyle(
                                          fontFamily: 'jua',
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activity.description,
                                    style: TextStyle(
                                      fontFamily: 'jua',
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 선택 표시
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.black87,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 새 활동 생성 폼
  Widget _buildCreateActivityForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '새 활동 추가',
            style: TextStyle(
              fontFamily: 'jua',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // 이모지 선택
          const Text(
            '아이콘 선택',
            style: TextStyle(
              fontFamily: 'jua',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 이모지 그리드
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                final isSelected = emoji == _selectedEmoji;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryColor, width: 2)
                          : Border.all(color: Colors.grey[800]!, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 활동 이름
          AppTextField(
            controller: _nameController,
            hintText: '활동 이름',
            validator: Validators.validateActivityName,
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // 활동 설명
          AppTextField(
            controller: _descriptionController,
            hintText: '간단한 설명 (선택사항)',
            validator: Validators.validateActivityDescription,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // 활동 시간
          AppTextField(
            controller: _durationController,
            hintText: '시간 (분)',
            keyboardType: TextInputType.number,
            validator: Validators.validateMinutes,
            maxLines: 1,
          ),
          const SizedBox(height: 32),

          // 버튼
          Row(
            children: [
              // 취소 버튼
              Expanded(
                child: AppButton(
                  text: '취소',
                  onPressed: _hideCreateActivityForm,
                  backgroundColor: Colors.transparent,
                  textColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),

              // 생성 버튼
              Expanded(
                child: AppButton(
                  text: '추가',
                  onPressed: _isLoading ? null : _createActivity,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

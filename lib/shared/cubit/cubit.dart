import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo_app/modules/archived_tasks/archived_tasks_screen.dart';
import 'package:todo_app/modules/done_tasks/done_tasks_screen.dart';
import 'package:todo_app/modules/new_tasks/new_tasks_screen.dart';
import 'package:todo_app/shared/cubit/states.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);
  int currentIndex = 0;
  List<Widget> screens = [
    const NewScreen(),
    const DoneScreen(),
    const ArchivedScreen()
  ];
  List<String> titles = ['New Tasks', 'Done Tasks', 'Archived Tasks'];

  void changeIndex(int index) {
    currentIndex = index;
    emit(AppChangeNavBottomBarState());
  }

  bool bottomSheetShown = false;
  IconData fabIcon = Icons.edit;

  void changeBottomSheet(bool isShow, IconData icon) {
    bottomSheetShown = isShow;
    fabIcon = icon;
  }

  Database? database;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  void createDataBase() {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) {
        if (kDebugMode) {
          print('DB created');
        }
        database
            .execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, data TEXT, time TEXT, status TEXT)')
            .then((value) {
          if (kDebugMode) {
            print('Tables created');
          }
        }).catchError((e) {
          if (kDebugMode) {
            print('ERROR when created tables ${e.toString()}');
          }
        });
      },
      onOpen: (database) {
        getDataBase(database);
        if (kDebugMode) {
          print('DB Open');
        }
      },
    ).then((value) {
      database = value;
      emit(AppCreateDataBaseState());
    });
  }

  insertDataBase({
    required String title,
    required String time,
    required String date,
  }) async {
    await database!.transaction((txn) async {
      txn
          .rawInsert(
              'INSERT INTO tasks(title, data, time, status)VALUES("$title", "$date", "$time", "sa")')
          .then((value) {
        if (kDebugMode) {
          print('$value data base inserted');
        }
        emit(AppInsertDataBaseState());
        getDataBase(database);
      }).catchError((e) {
        if (kDebugMode) {
          print('ERROR when created tables ${e.toString()}');
        }
      });
      return null;
    });
  }

  void getDataBase(database) {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];

    emit(AppGetDataBaseLoadingState());

    database!.rawQuery('SELECT * FROM tasks').then((value) {
      // tasks = value;
      value.forEach((element) {
        if (element['status'] == 'new') {
          newTasks.add(element);
        } else if (element['status'] == 'done') {
          doneTasks.add(element);
        } else {
          archivedTasks.add(element);
        }
      });
      emit(AppGetDataBaseState());
    });
  }

  void updateDataBase(
    String status,
    int id,
  ) async {
    database!.rawUpdate(
      'UPDATE tasks SET status = ? WHERE id = ?',
      [status, id],
    ).then((value) {
      getDataBase(database);
      emit(AppUpdateDataBaseState());
    });
  }

  void deleteDataBase(
    int id,
  ) async {
    database!.rawUpdate(
      'DELETE FROM tasks WHERE id = ?',
      [id],
    ).then((value) {
      emit(AppGetDataBaseLoadingState());
    });
  }
}
